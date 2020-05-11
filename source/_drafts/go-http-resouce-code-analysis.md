---
title: Go http 标准库创建 http server 
tags:
---

`net/http` 可以用来处理 HTTP 协议，包括 HTTP 服务器和 HTTP 客户端，主要组成：

- Request，HTTP 请求对象
- Response，HTTP 响应对象
- Client，HTTP 客户端
- Server，HTTP 服务端

创建一个 server ：

```go
package main

import (
	"fmt"
	"net/http"
)

func MyHandler(w http.ResponseWriter, r *http.Request) {
	_, _ = fmt.Fprintf(w, "hello")
}

func main() {
	http.HandleFunc("/", MyHandler)
	_ = http.ListenAndServe(":8080", nil)
}
```

`server.go` 文件中定义了一个非常重要的接口：`Handler`，另外还有一个结构体 `response`，这和 `http.Response` 结构体只有首字母大小
写不一致，这个 `response` 也是响应，只不过是专门用在服务端，和 `http.Response` 结构体是完全两回事。

```go
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}

type Server struct

// 监听 srv.Addr 然后调用 Serve 来处理接下来连接的请求
// 如果 srv.Addr 是空的话，则使用 ":http"
func (srv *Server) ListenAndServe() error 

// 监听 srv.Addr ，调用 Serve 来处理接下来连接的请求
// 必须提供证书文件和对应的私钥文件。如果证书是由
// 权威机构签发的，certFile 参数必须是顺序串联的服务端证书和 CA 证书。

func (srv *Server) ListenAndServeTLS(certFile, keyFile string) error 

// 接受 l Listener 的连接，创建一个新的服务协程。该服务协程读取请求然后调用
// srv.Handler 来应答。实际上就是实现了对某个端口进行监听，然后创建相应的连接。 
func (srv *Server) Serve(l net.Listener) error

// 该函数控制是否 http 的 keep-alives 能够使用，默认情况下，keep-alives 总是可用的。
// 只有资源非常紧张的环境或者服务端在关闭进程中时，才应该关闭该功能。 
func (s *Server) SetKeepAlivesEnabled(v bool)

// 是一个 http 请求多路复用器，它将每一个请求的 URL 和
// 一个注册模式的列表进行匹配，然后调用和 URL 最匹配的模式的处理器进行后续操作。
type ServeMux

// 初始化一个新的 ServeMux 
func NewServeMux() *ServeMux

// 将 handler 注册为指定的模式，如果该模式已经有了 handler，则会出错 panic。
func (mux *ServeMux) Handle(pattern string, handler Handler) 

// 将 handler 注册为指定的模式 
func (mux *ServeMux) HandleFunc(pattern string, handler func(ResponseWriter, *Request))

// 根据指定的 r.Method, r.Host 以及 r.RUL.Path 返回一个用来处理给定请求的 handler。
// 该函数总是返回一个 非 nil 的 handler，如果 path 不是一个规范格式，则 handler 会
// 重定向到其规范 path。Handler 总是返回匹配该请求的的已注册模式；在内建重定向
// 处理器的情况下，pattern 会在重定向后进行匹配。如果没有已注册模式可以应用于该请求，
// 本方法将返回一个内建的 ”404 page not found” 处理器和一个空字符串模式。
func (mux *ServeMux) Handler(r *Request) (h Handler, pattern string) 

// 该函数用于将最接近请求 url 模式的 handler 分配给指定的请求。 
func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request)
```

`Handler` 接口是 `server.go` 中最关键的接口，如果我们仔细看这个文件的源代码，将会发现很多结构体实现了这个接口的 `ServeHTTP` 方法。

注意这个接口的注释：`Handler` 响应 HTTP 请求。没错，最终我们的 HTTP 服务是通过实现 `ServeHTTP(ResponseWriter, *Request)` 来达
到服务端接收客户端请求并响应。

```go
func main() {
	http.HandleFunc("/", MyHandler)
	_ = http.ListenAndServe(":8080", nil)
}
```

而 `type HandlerFunc func(ResponseWriter, *Request)` 是一个函数类型，而我们定义的 `MyHandler` 的函数签名刚好符合这个函数类型。

所以 `http.HandleFunc("/", MyHandler)`，实际上是 `mux.Handle("/", HandlerFunc(MyHandler))`。

`HandlerFunc(MyHandler)` 让 `MyHandler` 成为了 `HandlerFunc` 类型，我们称 `MyHandler` 为 `handler`。而 `HandlerFunc` 类型是
具有 `ServeHTTP` 方法的，而有了 `ServeHTTP` 方法也就是实现了 `Handler` 接口。

```go
func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
	f(w, r) // 这相当于自身的调用
}

```
现在 `ServeMux` 和 `Handler` 都和我们的 `MyHandler` 联系上了，`MyHandler` 是一个 `Handler` 接口变量也是 `HandlerFunc` 类型变量，
接下来和结构体 `server` 有关了。

从 `http.ListenAndServe` 的源码可以看出，它创建了一个 `server` 对象，并调用 `server` 对象的 `ListenAndServe` 方法：

```go
func ListenAndServe(addr string, handler Handler) error {
    server := &Server{Addr: addr, Handler: handler}
    return server.ListenAndServe()
}
```
而我们 HTTP 服务器中第二行代码：

```go
http.ListenAndServe(":8080", nil)
```

创建了一个 `server` 对象，并调用 `server` 对象的 `ListenAndServe` 方法，这里没有直接传递 `Handler`，而是默认
使用 `DefautServeMux` 作为 `multiplexer`。

`Server` 的 `ListenAndServe` 方法中，会初始化监听地址 `Addr`，同时调用 `Listen` 方法设置监听。

```go
for {
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
    tempDelay = 0
    c := srv.newConn(rw)
    c.setState(c.rwc, StateNew) // before Serve can return
    go c.serve(ctx)
}
```
监听开启之后，一旦客户端请求过来，Go 就开启一个协程 `go c.serve(ctx)` 处理请求，主要逻辑都在 `serve` 方法之中。

`func (c *conn) serve(ctx context.Context)`，这个方法很长，里面主要的一句：`serverHandler{c.server}.ServeHTTP(w, w.req)`。
其中 `w` 由 `w, err := c.readRequest(ctx)` 得到，因为有传递 `context`。

还是来看源代码：

```go
// serverHandler delegates to either the server's Handler or
// DefaultServeMux and also handles "OPTIONS *" requests.
type serverHandler struct {
	srv *Server
}


func (sh serverHandler) ServeHTTP(rw ResponseWriter, req *Request) {
    // 此 handler 即为 http.ListenAndServe 中的第二个参数
    handler := sh.srv.Handler 
    if handler == nil {
        // 如果 handler 为空则使用内部的 DefaultServeMux 进行处理
        handler = DefaultServeMux
    }
    if req.RequestURI == "*" && req.Method == "OPTIONS" {
        handler = globalOptionsHandler{}
    }
    // 这里就开始处理 http 请求
    // 如果需要使用自定义的 mux，就需要实现 ServeHTTP 方法，即实现 Handler 接口。
    // ServeHTTP(rw, req) 默认情况下是 func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request)
    handler.ServeHTTP(rw, req)
}
```
从 `http.ListenAndServe(":8080", nil)` 开始，`handler` 是 `nil`，所以最后实际 `ServeHTTP` 方法
是 `DefaultServeMux.ServeHTTP(rw, req)`。

```go
func (mux *ServeMux) ServeHTTP(w ResponseWriter, r *Request) {
	if r.RequestURI == "*" {
		if r.ProtoAtLeast(1, 1) {
			w.Header().Set("Connection", "close")
		}
		w.WriteHeader(StatusBadRequest)
		return
	}
	h, _ := mux.Handler(r) // 会匹配路由，h 就是 MyHandler
	h.ServeHTTP(w, r) // 调用自己
}

func (mux *ServeMux) Handler(r *Request) (h Handler, pattern string) {

	// CONNECT requests are not canonicalized.
	if r.Method == "CONNECT" {
		// If r.URL.Path is /tree and its handler is not registered,
		// the /tree -> /tree/ redirect applies to CONNECT requests
		// but the path canonicalization does not.
		if u, ok := mux.redirectToPathSlash(r.URL.Host, r.URL.Path, r.URL); ok {
			return RedirectHandler(u.String(), StatusMovedPermanently), u.Path
		}

		return mux.handler(r.Host, r.URL.Path)
	}

	// All other requests have any port stripped and path cleaned
	// before passing to mux.handler.
	host := stripHostPort(r.Host)
	path := cleanPath(r.URL.Path)

	// If the given path is /tree and its handler is not registered,
	// redirect for /tree/.
	if u, ok := mux.redirectToPathSlash(host, path, r.URL); ok {
		return RedirectHandler(u.String(), StatusMovedPermanently), u.Path
	}

	if path != r.URL.Path {
		_, pattern = mux.handler(host, path)
		url := *r.URL
		url.Path = path
		return RedirectHandler(url.String(), StatusMovedPermanently), pattern
	}

	return mux.handler(host, r.URL.Path)
}

// handler is the main implementation of Handler.
// The path is known to be in canonical form, except for CONNECT methods.
func (mux *ServeMux) handler(host, path string) (h Handler, pattern string) {
	mux.mu.RLock()
	defer mux.mu.RUnlock()

	// Host-specific pattern takes precedence over generic ones
	if mux.hosts {
		h, pattern = mux.match(host + path)
	}
	if h == nil {
		h, pattern = mux.match(path)
	}
	if h == nil {
		h, pattern = NotFoundHandler(), ""
	}
	return
}
```

通过 `func (mux *ServeMux) Handler(r *Request) (h Handler, pattern string)`，我们得到 `Handler h`，然后执
行 `h.ServeHTTP(w, r)` 方法，也就是执行我们的 `MyHandler` 函数（别忘了 `MyHandler` 是HandlerFunc类型，而他的 `ServeHTTP(w, r)` 
方法这里其实就是自己调用自己），把 `response` 写到 `http.ResponseWriter` 对象返回给客户端，`fmt.Fprintf(w, "hello")`，我们在客
户端会接收到 "hello" 。至此整个 HTTP 服务执行完成。


总结下，HTTP 服务整个过程大概是这样：
```go
Request -> ServeMux(Multiplexer) -> handler-> Response
```

我们再看下面代码：

```go
http.ListenAndServe(":8080", nil)
func ListenAndServe(addr string, handler Handler) error {
    server := &Server{Addr: addr, Handler: handler}
    return server.ListenAndServe()
}
```

上面代码实际上就是 `server.ListenAndServe()` 执行的实际效果，只不过简单声明了一个结构体 `Server{Addr: addr, Handler: handler}` 实例。
如果我们声明一个 `Server` 实例，完全可以达到深度自定义 `http.Server` 的目的：


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
我们完全可以根据情况来自定义我们的 `Server`。

还可以指定 `Servemux` 的用法:

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

如果既指定 `Servemux` 又自定义 `http.Server`，因为 `Server` 中有字段 `Handler`，所以我们可以直接把 `Servemux` 变量作
为 `Server.Handler`：


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

## 自定义处理器

自定义的 `Handler`：

标准库 http 提供了 `Handler` 接口，用于开发者实现自己的 `handler`。只要实现接口的 `ServeHTTP` 方法即可。

```go
package main

import (
	"log"
	"net/http"
	"time"
)

type timeHandler struct {
	format string
}

func (th *timeHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	tm := time.Now().Format(th.format)
	_, _ = w.Write([]byte("The time is: " + tm))
}

func main() {
	mux := http.NewServeMux()

	th := &timeHandler{format: time.RFC1123}
	mux.Handle("/time", th)

	log.Println("Listening...")
	_ = http.ListenAndServe(":3000", mux)
}
```
我们知道，`NewServeMux` 可以创建一个 `ServeMux` 实例，`ServeMux` 同时也实现了 `ServeHTTP` 方法，因此代码中的 `mux` 也是
一种 `handler`。把它当成参数传给 `http.ListenAndServe` 方法，后者会把 `mux` 传给 `Server` 实例。因为指定了 `handler`，
因此整个 `http` 服务就不再是 `DefaultServeMux`，而是 `mux`，无论是在注册路由还是提供请求服务的时候。

任何有 `func(http.ResponseWriter，*http.Request)` 签名的函数都能转化为一个 `HandlerFunc` 类型。这很有用，因为 `HandlerFunc` 对象
内置了 `ServeHTTP` 方法，后者可以聪明又方便的调用我们最初提供的函数内容。

## 中间件 Middleware

所谓中间件，就是连接上下级不同功能的函数或者软件，通常进行一些包裹函数的行为，为被包裹函数提供添加一些功能或行为。前文的 `HandleFunc` 就
能把签名为 `func(w http.ResponseWriter, r *http.Reqeust)` 的函数包裹成 `handler`。这个函数也算是中间件。

Go 的 HTTP 中间件很简单，只要实现一个函数签名为 `func(http.Handler) http.Handler` 的函数即可。`http.Handler` 是一个接口，
接口方法我们熟悉的为 `serveHTTP`。返回也是一个 `handler`。因为 Go 中的函数也可以当成变量传递或者或者返回，因此也可以在中间件函数
中传递定义好的函数，只要这个函数是一个 `handler` 即可，即实现或者被 `handlerFunc` 包裹成为 `handler` 处理器。

```go
func index(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "text/html")

    html := `<doctype html>
        <html>
        <head>
          <title>Hello World</title>
        </head>
        <body>
        <p>
          Welcome
        </p>
        </body>
</html>`
    fmt.Fprintln(w, html)
}

func middlewareHandler(next http.Handler) http.Handler{
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request){
        // 执行 handler 之前的逻辑
        next.ServeHTTP(w, r)
        // 执行完毕 handler 后的逻辑
    })
}

func loggingHandler(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        log.Printf("Started %s %s", r.Method, r.URL.Path)
        next.ServeHTTP(w, r)
        log.Printf("Completed %s in %v", r.URL.Path, time.Since(start))
    })
}

func main() {
    http.Handle("/", loggingHandler(http.HandlerFunc(index)))

    http.ListenAndServe(":8000", nil)
}
```

## 静态站点

下面代码通过指定目录，作为静态站点：
```go
package main

import (
	"net/http"
)

func main() {
	http.Handle("/", http.FileServer(http.Dir("D:/html/static/")))
	_ = http.ListenAndServe(":8080", nil)
}
```