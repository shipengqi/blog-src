---
title: node-http-resouce-code-analysis
tags:
---

使用 Node.js 创建一个 HTTP 服务器

```javascript
const http = require('http');
http.createServer(function (request, response) {
    response.end('Hello World\n');
}).listen(8080);
```

`lib/http.js`
```javascript
function createServer(opts, requestListener) {
  return new Server(opts, requestListener);
}
```

`lib/_http_server.js`
```javascript
function Server(options, requestListener) {
  if (!(this instanceof Server)) return new Server(options, requestListener);

  // options 是可选的
  if (typeof options === 'function') {
    requestListener = options;
    options = {};
  } else if (options == null || typeof options === 'object') {
    options = { ...options };
  } else {
    throw new ERR_INVALID_ARG_TYPE('options', 'object', options);
  }

  this[kIncomingMessage] = options.IncomingMessage || IncomingMessage;
  this[kServerResponse] = options.ServerResponse || ServerResponse;

  const maxHeaderSize = options.maxHeaderSize;
  if (maxHeaderSize !== undefined)
    validateInteger(maxHeaderSize, 'maxHeaderSize', 0);
  this.maxHeaderSize = maxHeaderSize;

  const insecureHTTPParser = options.insecureHTTPParser;
  if (insecureHTTPParser !== undefined &&
      typeof insecureHTTPParser !== 'boolean') {
    throw new ERR_INVALID_ARG_TYPE(
      'options.insecureHTTPParser', 'boolean', insecureHTTPParser);
  }
  this.insecureHTTPParser = insecureHTTPParser;
  // 继承 net.Server 构造函数作用域
  net.Server.call(this, { allowHalfOpen: true });
  // 监听 request 事件，执行 createServer 传入的回调函数
  if (requestListener) {
    this.on('request', requestListener);
  }

  // Similar option to this. Too lazy to write my own docs.
  // http://www.squid-cache.org/Doc/config/half_closed_clients/
  // http://wiki.squid-cache.org/SquidFaq/InnerWorkings#What_is_a_half-closed_filedescriptor.3F
  this.httpAllowHalfOpen = false;
  // 监听 tcp 连接建立
  this.on('connection', connectionListener);

  this.timeout = 0;
  this.keepAliveTimeout = 5000;
  this.maxHeadersCount = null;
  this.headersTimeout = 60 * 1000; // 60 seconds
}
// 继承 net.Server 的 prototype
ObjectSetPrototypeOf(Server.prototype, net.Server.prototype);
ObjectSetPrototypeOf(Server, net.Server);
```

`lib/net.js`
```javascript
function Server(options, connectionListener) {
  if (!(this instanceof Server))
    return new Server(options, connectionListener);

  EventEmitter.call(this);

  if (typeof options === 'function') {
    connectionListener = options;
    options = {};
    this.on('connection', connectionListener);
  } else if (options == null || typeof options === 'object') {
    options = { ...options };

    if (typeof connectionListener === 'function') {
      this.on('connection', connectionListener);
    }
  } else {
    throw new ERR_INVALID_ARG_TYPE('options', 'Object', options);
  }

  this._connections = 0;

  ObjectDefineProperty(this, 'connections', {
    get: deprecate(() => {

      if (this._usingWorkers) {
        return null;
      }
      return this._connections;
    }, 'Server.connections property is deprecated. ' +
       'Use Server.getConnections method instead.', 'DEP0020'),
    set: deprecate((val) => (this._connections = val),
                   'Server.connections property is deprecated.',
                   'DEP0020'),
    configurable: true, enumerable: false
  });

  this[async_id_symbol] = -1;
  this._handle = null;
  this._usingWorkers = false;
  this._workers = [];
  this._unref = false;

  this.allowHalfOpen = options.allowHalfOpen || false;
  this.pauseOnConnect = !!options.pauseOnConnect;
}
ObjectSetPrototypeOf(Server.prototype, EventEmitter.prototype);
ObjectSetPrototypeOf(Server, EventEmitter);

Server.prototype.listen = function(...args) {
  // 处理入参，listen 可以接收好几个参数，这里是只传了端口号 8080
  const normalized = normalizeArgs(args); //  normalized = [{port: 8080}, null];
  let options = normalized[0];
  const cb = normalized[1];
  // 第一次 listen 的时候会创建，如果非空说明已经调用过 listen
  if (this._handle) {
    throw new ERR_SERVER_ALREADY_LISTEN();
  }

  if (cb !== null) {
    this.once('listening', cb);
  }
  const backlogFromArgs =
    // (handle, backlog) or (path, backlog) or (port, backlog)
    toNumber(args.length > 1 && args[1]) ||
    toNumber(args.length > 2 && args[2]);  // (port, host, backlog)

  options = options._handle || options.handle || options;
  const flags = getFlags(options.ipv6Only);
  // (handle[, backlog][, cb]) where handle is an object with a handle
  if (options instanceof TCP) {
    this._handle = options;
    this[async_id_symbol] = this._handle.getAsyncId();
    listenInCluster(this, null, -1, -1, backlogFromArgs);
    return this;
  }
  // (handle[, backlog][, cb]) where handle is an object with a fd
  if (typeof options.fd === 'number' && options.fd >= 0) {
    listenInCluster(this, null, null, null, backlogFromArgs, options.fd);
    return this;
  }

  // ([port][, host][, backlog][, cb]) where port is omitted,
  // that is, listen(), listen(null), listen(cb), or listen(null, cb)
  // or (options[, cb]) where options.port is explicitly set as undefined or
  // null, bind to an arbitrary unused port
  if (args.length === 0 || typeof args[0] === 'function' ||
      (typeof options.port === 'undefined' && 'port' in options) ||
      options.port === null) {
    options.port = 0;
  }
  // ([port][, host][, backlog][, cb]) where port is specified
  // or (options[, cb]) where options.port is specified
  // or if options.port is normalized as 0 before
  let backlog;
  if (typeof options.port === 'number' || typeof options.port === 'string') {
    validatePort(options.port, 'options.port');
    backlog = options.backlog || backlogFromArgs;
    // start TCP server listening on host:port
    if (options.host) {
      lookupAndListen(this, options.port | 0, options.host, backlog,
                      options.exclusive, flags);
    } else { // Undefined host, listens on unspecified address
      // Default addressType 4 will be used to search for master server
      listenInCluster(this, null, options.port | 0, 4,
                      backlog, undefined, options.exclusive);
    }
    return this;
  }

  // (path[, backlog][, cb]) or (options[, cb])
  // where path or options.path is a UNIX domain socket or Windows pipe
  if (options.path && isPipeName(options.path)) {
    const pipeName = this._pipeName = options.path;
    backlog = options.backlog || backlogFromArgs;
    listenInCluster(this, pipeName, -1, -1,
                    backlog, undefined, options.exclusive);

    if (!this._handle) {
      // Failed and an error shall be emitted in the next tick.
      // Therefore, we directly return.
      return this;
    }

    let mode = 0;
    if (options.readableAll === true)
      mode |= PipeConstants.UV_READABLE;
    if (options.writableAll === true)
      mode |= PipeConstants.UV_WRITABLE;
    if (mode !== 0) {
      const err = this._handle.fchmod(mode);
      if (err) {
        this._handle.close();
        this._handle = null;
        throw errnoException(err, 'uv_pipe_chmod');
      }
    }
    return this;
  }

  if (!(('port' in options) || ('path' in options))) {
    throw new ERR_INVALID_ARG_VALUE('options', options,
                                    'must have the property "port" or "path"');
  }

  throw new ERR_INVALID_OPT_VALUE('options', inspect(options));
};
```

```javascript
function listenInCluster() {
    ...
    server._listen2(address, port, addressType, backlog, fd);
}

_listen2 = setupListenHandle = function() {
    ...
    // 每一个服务器新建一个 handle 并且保存，该 handle 是一个TCP对象
    this._handle = createServerHandle(...);
    // 监听端口
    this._handle.listen(backlog || 511);
};
function createServerHandle() {
    handle = new TCP(TCPConstants.SERVER);
    // bind host 和 port
    handle.bind(address, port);
}
```

`new TCP` 做了什么， `src/tcp_wrap.cc`：
```c
void TCPWrap::New(const FunctionCallbackInfo<Value>& args) {
  // This constructor should not be exposed to public javascript.
  // Therefore we assert that we are not trying to call this as a
  // normal function.
  CHECK(args.IsConstructCall());
  CHECK(args[0]->IsInt32());
  Environment* env = Environment::GetCurrent(args);

  int type_value = args[0].As<Int32>()->Value();
  TCPWrap::SocketType type = static_cast<TCPWrap::SocketType>(type_value);c

  ProviderType provider;
  switch (type) {
    case SOCKET:
      provider = PROVIDER_TCPWRAP;
      break;
    case SERVER:
      provider = PROVIDER_TCPSERVERWRAP;
      break;
    default:
      UNREACHABLE();
  }

  new TCPWrap(env, args.This(), provider);
}

TCPWrap::TCPWrap(Environment* env, Local<Object> object, ProviderType provider)
    : ConnectionWrap(env, object, provider) {
  int r = uv_tcp_init(env->event_loop(), &handle_);
  CHECK_EQ(r, 0);  
}
```

`new TCP` 的时候其实是执行 libuv 的 `uv_tcp_init` 函数，初始化一个 `uv_tcp_t` 的结构体。


bind对应libuv的函数是`uv__tcp_bind`，listen对应的是`uv_tcp_listen`


nodejs是如何解析http协议

https://mp.weixin.qq.com/s?__biz=MzUyNDE2OTAwNw==&mid=100000359&idx=1&sn=4c078b521e9a1838ccd15f042808fd70&scene=19#wechat_redirect
https://mp.weixin.qq.com/s?__biz=MzUyNDE2OTAwNw==&mid=100000354&idx=1&sn=d093d83febf44b5f0fa01fddd2817967&scene=19#wechat_redirect