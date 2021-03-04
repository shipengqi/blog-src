---
title: Go http 库 server 源码分析
date: 2019-11-12 12:41:19
categories: ["Go"]
---

Go 的标准库 `net/http` 用来处理 HTTP 协议，包括 HTTP server 和 HTTP client。这里主要分析 HTTP server 部分。 

<!--more-->

## 请求处理流程分析

从一个示例开始：

```go
package main

import (
	"fmt"
  "html"
	"net/http"
)

func barHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))
}

func main() {
  http.HandleFunc("/bar", barHandler)
  // 监听端口并启动服务
	_ = http.ListenAndServe(":8080", nil)
}
```

`http.ListenAndServe`：

```go
// ListenAndServe always returns a non-nil error.
// 第二个参数是 Handler 接口类型，但是上面的示例传入的是 nil，这个后面会说到
func ListenAndServe(addr string, handler Handler) error {
	server := &Server{Addr: addr, Handler: handler}
	return server.ListenAndServe()
}
```

`http.ListenAndServe` 内部创建了一个 server 实例，并调用了 server 实例的 `ListenAndServe` 方法，`server.ListenAndServe`：
```go
func (srv *Server) ListenAndServe() error {
	if srv.shuttingDown() {
		return ErrServerClosed
	}
  // 如果 srv.Addr 是空的话，则使用 ":http"
	addr := srv.Addr
	if addr == "" {
		addr = ":http"
	}
  // 监听 tcp 端口
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}
  // 接受 l Listener 的连接，并创建一个新的 goroutine 处理请求
	return srv.Serve(ln)
}
```

`srv.Serve` 的实现：

```go
func (srv *Server) Serve(l net.Listener) error {
	if fn := testHookServerServe; fn != nil {
		fn(srv, l) // call hook with unwrapped listener
	}

	origListener := l
	l = &onceCloseListener{Listener: l}
	defer l.Close()

	if err := srv.setupHTTP2_Serve(); err != nil {
		return err
	}

	if !srv.trackListener(&l, true) {
		return ErrServerClosed
	}
	defer srv.trackListener(&l, false)

	var tempDelay time.Duration // how long to sleep on accept failure

  // 为每一个 request 创建 context 实例
	baseCtx := context.Background()
	if srv.BaseContext != nil {
		baseCtx = srv.BaseContext(origListener)
		if baseCtx == nil {
			panic("BaseContext returned a nil context")
		}
	}

	ctx := context.WithValue(baseCtx, ServerContextKey, srv)
	for {
    // 接受请求数据，返回一个新的连接句柄
		rw, e := l.Accept()
		if e != nil {
			select {
			case <-srv.getDoneChan():
				return ErrServerClosed
			default:
			}
			if ne, ok := e.(net.Error); ok && ne.Temporary() {
				if tempDelay == 0 {
					tempDelay = 5 * time.Millisecond
				} else {
					tempDelay *= 2
				}
				if max := 1 * time.Second; tempDelay > max {
					tempDelay = max
				}
				srv.logf("http: Accept error: %v; retrying in %v", e, tempDelay)
				time.Sleep(tempDelay)
				continue
			}
			return e
		}
		if cc := srv.ConnContext; cc != nil {
			ctx = cc(ctx, rw)
			if ctx == nil {
				panic("ConnContext returned nil")
			}
		}
		tempDelay = 0
    // 创建一个新连接
		c := srv.newConn(rw)
		c.setState(c.rwc, StateNew) // before Serve can return
    // 创建一个新的 goroutine，处理请求
		go c.serve(ctx)
	}
}
```

具体的请求处理逻辑就在 `c.serve(ctx)` 中：

```go
// Serve a new connection.
func (c *conn) serve(ctx context.Context) {
	c.remoteAddr = c.rwc.RemoteAddr().String()
	ctx = context.WithValue(ctx, LocalAddrContextKey, c.rwc.LocalAddr())
	defer func() {
		if err := recover(); err != nil && err != ErrAbortHandler {
			const size = 64 << 10
			buf := make([]byte, size)
			buf = buf[:runtime.Stack(buf, false)]
			c.server.logf("http: panic serving %v: %v\n%s", c.remoteAddr, err, buf)
		}
		if !c.hijacked() {
			c.close()
			c.setState(c.rwc, StateClosed)
		}
	}()

	if tlsConn, ok := c.rwc.(*tls.Conn); ok {
		if d := c.server.ReadTimeout; d != 0 {
			c.rwc.SetReadDeadline(time.Now().Add(d))
		}
		if d := c.server.WriteTimeout; d != 0 {
			c.rwc.SetWriteDeadline(time.Now().Add(d))
		}
		if err := tlsConn.Handshake(); err != nil {
			// If the handshake failed due to the client not speaking
			// TLS, assume they're speaking plaintext HTTP and write a
			// 400 response on the TLS conn's underlying net.Conn.
			if re, ok := err.(tls.RecordHeaderError); ok && re.Conn != nil && tlsRecordHeaderLooksLikeHTTP(re.RecordHeader) {
				io.WriteString(re.Conn, "HTTP/1.0 400 Bad Request\r\n\r\nClient sent an HTTP request to an HTTPS server.\n")
				re.Conn.Close()
				return
			}
			c.server.logf("http: TLS handshake error from %s: %v", c.rwc.RemoteAddr(), err)
			return
		}
		c.tlsState = new(tls.ConnectionState)
		*c.tlsState = tlsConn.ConnectionState()
		if proto := c.tlsState.NegotiatedProtocol; validNPN(proto) {
			if fn := c.server.TLSNextProto[proto]; fn != nil {
				h := initNPNRequest{ctx, tlsConn, serverHandler{c.server}}
				fn(c.server, tlsConn, h)
			}
			return
		}
	}

	// HTTP/1.x from here on.
	ctx, cancelCtx := context.WithCancel(ctx)
	c.cancelCtx = cancelCtx
	defer cancelCtx()

	c.r = &connReader{conn: c}
	c.bufr = newBufioReader(c.r)
	c.bufw = newBufioWriterSize(checkConnErrorWriter{c}, 4<<10)

	for {
    // 读取请求数据
		w, err := c.readRequest(ctx)
		if c.r.remain != c.server.initialReadLimitSize() {
		  // If we read any bytes off the wire, we're active.
			c.setState(c.rwc, StateActive)
		}
		if err != nil {
			const errorHeaders = "\r\nContent-Type: text/plain; charset=utf-8\r\nConnection: close\r\n\r\n"

			switch {
			case err == errTooLarge:
				// Their HTTP client may or may not be
				// able to read this if we're
				// responding to them and hanging up
				// while they're still writing their
				// request. Undefined behavior.
				const publicErr = "431 Request Header Fields Too Large"
				fmt.Fprintf(c.rwc, "HTTP/1.1 "+publicErr+errorHeaders+publicErr)
				c.closeWriteAndWait()
				return

			case isUnsupportedTEError(err):
				// Respond as per RFC 7230 Section 3.3.1 which says,
				//      A server that receives a request message with a
				//      transfer coding it does not understand SHOULD
				//      respond with 501 (Unimplemented).
				code := StatusNotImplemented

				// We purposefully aren't echoing back the transfer-encoding's value,
				// so as to mitigate the risk of cross side scripting by an attacker.
				fmt.Fprintf(c.rwc, "HTTP/1.1 %d %s%sUnsupported transfer encoding", code, StatusText(code), errorHeaders)
				return

			case isCommonNetReadError(err):
				return // don't reply

			default:
				publicErr := "400 Bad Request"
				if v, ok := err.(badRequestError); ok {
					publicErr = publicErr + ": " + string(v)
				}

				fmt.Fprintf(c.rwc, "HTTP/1.1 "+publicErr+errorHeaders+publicErr)
				return
			}
		}

		// Expect 100 Continue support
		req := w.req
		if req.expectsContinue() {
			if req.ProtoAtLeast(1, 1) && req.ContentLength != 0 {
				// Wrap the Body reader with one that replies on the connection
				req.Body = &expectContinueReader{readCloser: req.Body, resp: w}
			}
		} else if req.Header.get("Expect") != "" {
			w.sendExpectationFailed()
			return
		}

		c.curReq.Store(w)

		if requestBodyRemains(req.Body) {
			registerOnHitEOF(req.Body, w.conn.r.startBackgroundRead)
		} else {
			w.conn.r.startBackgroundRead()
		}

		// HTTP cannot have multiple simultaneous active requests.[*]
		// Until the server replies to this request, it can't read another,
		// so we might as well run the handler in this goroutine.
		// [*] Not strictly true: HTTP pipelining. We could let them all process
		// in parallel even if their responses need to be serialized.
		// But we're not going to implement HTTP pipelining because it
		// was never deployed in the wild and the answer is HTTP/2.
    // 将 c.server 放到了 serverHandler 结构中，serverHandler 实现了 Handler 接口
    // 调用 ServeHTTP 方法处理请求
		serverHandler{c.server}.ServeHTTP(w, w.req)
		w.cancelCtx()
		if c.hijacked() {
			return
		}
		w.finishRequest()
		if !w.shouldReuseConnection() {
			if w.requestBodyLimitHit || w.closedRequestBodyEarly() {
				c.closeWriteAndWait()
			}
			return
		}
		c.setState(c.rwc, StateIdle)
		c.curReq.Store((*response)(nil))

		if !w.conn.server.doKeepAlives() {
			// We're in shutdown mode. We might've replied
			// to the user without "Connection: close" and
			// they might think they can send another
			// request, but such is life with HTTP/1.1.
			return
		}

		if d := c.server.idleTimeout(); d != 0 {
			c.rwc.SetReadDeadline(time.Now().Add(d))
			if _, err := c.bufr.Peek(4); err != nil {
				return
			}
		}
		c.rwc.SetReadDeadline(time.Time{})
	}
}
```

```go
func (sh serverHandler) ServeHTTP(rw ResponseWriter, req *Request) {
    // 此 handler 即为 http.ListenAndServe 的第二个参数
    handler := sh.srv.Handler 
    // 如果 handler 为空则使用默认的 DefaultServeMux
    if handler == nil {
        handler = DefaultServeMux
    }
    if req.RequestURI == "*" && req.Method == "OPTIONS" {
        handler = globalOptionsHandler{}
    }
    // 调用 ServeHTTP 方法处理 http 请求
    // http.ListenAndServe 的第二个参数传入了自定义的 mux，就需要实现 ServeHTTP 方法，也就是实现 Handler 接口。比如 gin 的 Engine 对象
    handler.ServeHTTP(rw, req)
}
```

默认的 `DefaultServeMux` 的 `ServeMux` 类型，`ServeMux` 的 `ServeHTTP` 实现：
```go
// ServeHTTP dispatches the request to the handler whose
// pattern most closely matches the request URL.
func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request) {
	if r.RequestURI == "*" {
		if r.ProtoAtLeast(1, 1) {
			w.Header().Set("Connection", "close")
		}
		w.WriteHeader(StatusBadRequest)
		return
	}
	h, _ := mux.Handler(r) // 路由匹配，获取到路由处理函数，这里得到的应该是示例中的 barHandler 函数
	h.ServeHTTP(w, r) // 调用自己
}
```

上面的代码 `h.ServeHTTP(w, r)` 之所以说调用自己，是应为 路由 handler 在注册是被转换为了 `HandlerFunc` 类型，而这个类型实现的 `ServeHTTP`
方法（即实现了 `Handler` 接口），就是调用自己。如下：
```go
type HandlerFunc func(ResponseWriter, *Request)

// ServeHTTP calls f(w, r).
func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
	f(w, r) // 调用自己
}
```
这里调用自己就是执行 `fmt.Fprintf(w, "Hello, %q", html.EscapeString(r.URL.Path))`，把 `response` 写到 `http.ResponseWriter` 对
象返回给客户端，`fmt.Fprintf(w, "hello")`，然后客户端接收到 "Hello, /bar" 。这就是整个 HTTP 服务执行的流程。

## 路由注册
在来看示例中的 `http.HandleFunc` 是怎么添加 Handler 的：
```go
func HandleFunc(pattern string, handler func(ResponseWriter, *Request)) {
	DefaultServeMux.HandleFunc(pattern, handler)
}
```

可以看出 `http.HandleFunc` 其实是调用了默认的 `DefaultServeMux` 的 `HandleFunc` 添加 Handler。这就对应了上面的 `ServeHTTP` 方法中
下面的这段代码：
```go
    // 如果 handler 为空则使用默认的 DefaultServeMux
    if handler == nil {
        handler = DefaultServeMux
    }
```

也就是说在调用 `http.ListenAndServe` 如果没有传入 mux，那么就会使用默认的 `DefaultServeMux`。

`DefaultServeMux.HandleFunc` 的实现：
```go
// HandleFunc registers the handler function for the given pattern.
func (mux *ServeMux) HandleFunc(pattern string, handler func(ResponseWriter, *Request)) {
	if handler == nil {
		panic("http: nil handler")
	}
  // 根据示例，这里应该是 mux.Handle("/bar", HandlerFunc(barHandler))
  // 将 handler 显示转换成了 HandlerFunc 类型
	mux.Handle(pattern, HandlerFunc(handler))
}

// Handle registers the handler for the given pattern.
// If a handler already exists for pattern, Handle panics.
func (mux *ServeMux) Handle(pattern string, handler Handler) {
	mux.mu.Lock()
	defer mux.mu.Unlock()
  // 校验路由 path 和 路由 handler 函数
	if pattern == "" {
		panic("http: invalid pattern")
	}
	if handler == nil {
		panic("http: nil handler")
	}
  // 不能重复注册
	if _, exist := mux.m[pattern]; exist {
		panic("http: multiple registrations for " + pattern)
	}
  // 初始化 map，存放注册的路由
	if mux.m == nil {
		mux.m = make(map[string]muxEntry)
	}
  // 保存路由对象
	e := muxEntry{h: handler, pattern: pattern}
	mux.m[pattern] = e
	if pattern[len(pattern)-1] == '/' {
		mux.es = appendSorted(mux.es, e)
	}

	if pattern[0] != '/' {
		mux.hosts = true
	}
}
```

## 其他用法

### 自定义 http.Server

```go
package main

import (
	"fmt"
	"net/http"
)

func MyHandler(w http.ResponseWriter, r *http.Request) {
	_, _ = fmt.Fprintf(w, "hi")
}

func main() {
	// 更多http.Server的字段可以根据情况初始化
	server := http.Server{
		Addr:         ":8080",
		ReadTimeout:  0,
		WriteTimeout: 0,
	}
	http.HandleFunc("/", MyHandler)
	_ = server.ListenAndServe()
}
```

### 指定 http.Servemux:

```go
package main

import (
	"fmt"
	"net/http"
)

func MyHandler(w http.ResponseWriter, r *http.Request) {
	_, _ = fmt.Fprintf(w, "hi")
}

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("/", MyHandler)
	_ = http.ListenAndServe(":8080", mux)
}
```

也可以直接把 `Servemux` 变量作为 `Server.Handler`：


```go
package main

import (
	"fmt"
	"net/http"
)

func MyHandler(w http.ResponseWriter, r *http.Request) {
	_, _ = fmt.Fprintf(w, "hi")
}

func main() {
	server := http.Server{
		Addr:         ":8080",
		ReadTimeout:  0,
		WriteTimeout: 0,
	}
	mux := http.NewServeMux()
	server.Handler = mux

	mux.HandleFunc("/", MyHandler)
	_ = server.ListenAndServe()
}
```

## 自定义 mux

标准库 http 提供了 `Handler` 接口，自定义 mux 必须实现这个 `Handler` 接口。也就是实现 `ServeHTTP` 方法。
