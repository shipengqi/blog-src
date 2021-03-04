---
title: koa2 框架源码分析
date: 2019-06-10 14:05:18
categories: ["Node.js"]
---

[koa2](https://github.com/koajs/koa) 是基于 Node.js 实现的一个 web 框架。非常简洁，轻量，所有的功能都以插件的形式实现，开发者可以
按需引入。

<!--more-->

我们从一个官方示例开始，来看看 koa 的实现原理：

```javascript
const Koa = require('koa');
const app = new Koa();

app.use(async ctx => {
  ctx.body = 'Hello World';
});

app.listen(3000);
```

koa 的源码主要有四个文件，分别是 `application.js`、`context.js`、`request.js`、`response.js`。

`application.js` 是 koa 的入口文件，`app.use` 和 `app.listen` 的实现就在这个文件中。

## application.js

`new Koa()` 创建了一个 Application 实例，Application 的构造函数：

```javascript
const Emitter = require('events');
class Application extends Emitter {
    constructor(options) {
        super();
        options = options || {};
        this.proxy = options.proxy || false;
        this.subdomainOffset = options.subdomainOffset || 2;
        this.proxyIpHeader = options.proxyIpHeader || 'X-Forwarded-For';
        this.maxIpsCount = options.maxIpsCount || 0;
        this.env = options.env || process.env.NODE_ENV || 'development';
        if (options.keys) this.keys = options.keys;
        this.middleware = [];
        this.context = Object.create(context);
        this.request = Object.create(request);
        this.response = Object.create(response);
        if (util.inspect.custom) {
          this[util.inspect.custom] = this.inspect;
        }
    }
}
```

Application 类继承了 events，这样 app 就有了事件监听的能力。构造函数还为实例添加了一系列的属性，比如经常会用到的 `middleware`、
`context`、`request`、`response` 等。

Application 还暴露了一些常用的方法，比如 `listen`、`use` 等等。

我们从 `listen` 方法开始分析：

```javascript
listen(...args) {
    debug('listen');
    const server = http.createServer(this.callback());
    return server.listen(...args);
}
```

`listen` 方法其实就是对 `http.createServer` 进行了一个简单的封装。这里启动的 http server。如果要启用 https，就不能使用 `listen`
方法了，可以直接使用 https 包来创建：

```javascript
const https = require('https');
const Koa = require('koa');
const app = new Koa();
https.createServer(app.callback()).listen(3001);
```

`listen` 方法中应该关注 `callback` 的实现：

```javascript
callback() {
    const fn = compose(this.middleware);

    if (!this.listenerCount('error')) this.on('error', this.onerror);

    const handleRequest = (req, res) => {
      const ctx = this.createContext(req, res);
      return this.handleRequest(ctx, fn);
    };

    return handleRequest;
}
```

`compose(this.middleware)` 是引用的插件 `koa-compose` 的方法。
`middlleware` 是一个数组，存放的是通过 `app.use` 添加的中间件。

`app.use` 如何添加中间件：

```javascript
use(fn) {
    // 检查传入的中间件是否是函数
    if (typeof fn !== 'function') throw new TypeError('middleware must be a function!');
    if (isGeneratorFunction(fn)) { // 检查是否是 generator 函数，为了兼容 koa1
        deprecate('Support for generators will be removed in v3. ' +
                'See the documentation for examples of how to convert old middleware ' +
                'https://github.com/koajs/koa/blob/master/docs/migration.md');
        fn = convert(fn); // 将 koa1 中的 generator 函数转为 Promise 函数
    }
    debug('use %s', fn._name || fn.name || '-');
    this.middleware.push(fn); // 把中间件添加到 middleware 数组
    return this; // 返回 this，链式调用
}
```

`compose` 方法是 koa 中间件机制最重要的部分：

```javascript
/**
 * Compose `middleware` returning
 * a fully valid middleware comprised
 * of all those which are passed.
 *
 * @param {Array} middleware
 * @return {Function}
 * @api public
 */

function compose (middleware) {
  // 检查传入的中间件数组，是否是一个真的数组
  if (!Array.isArray(middleware)) throw new TypeError('Middleware stack must be an array!')
  for (const fn of middleware) { // 检查数组中的元素是否是函数
    if (typeof fn !== 'function') throw new TypeError('Middleware must be composed of functions!')
  }

  /**
   * @param {Object} context
   * @return {Promise}
   * @api public
   */

  return function (context, next) { // 这里返回一个函数，koa 的 ctx 和 next 作为参数
    // last called middleware #
    let index = -1
    return dispatch(0)
    function dispatch (i) {
      if (i <= index) return Promise.reject(new Error('next() called multiple times'))
      index = i
      let fn = middleware[i]
      if (i === middleware.length) fn = next
      if (!fn) return Promise.resolve()
      try {
        return Promise.resolve(fn(context, dispatch.bind(null, i + 1)));
      } catch (err) {
        return Promise.reject(err)
      }
    }
  }
}
```

`compose` 返回了一个函数， 先不管函数里面怎么执行，接着回到 Application 的`callback` 方法：

```javascript
callback() {
    const fn = compose(this.middleware);

    if (!this.listenerCount('error')) this.on('error', this.onerror); //  listenerCount 是继承与 event 对象的方法。判断是否监听了 error 事件,
                                                                      // 如果没有，添加 error 事件监听

    const handleRequest = (req, res) => { // req 和 res 作为参数
      const ctx = this.createContext(req, res); // 使用原生 request 和 response 对象创建 koa 的 Context 对象
      return this.handleRequest(ctx, fn); // 处理请求，传入 compose 返回的 fn 函数，串行执行中间件
    };

    return handleRequest;
}
```

`callback` 方法返回了一个 `handleRequest` 函数，这是 `http.createServer` 接收的回调函数。`handleRequest` 方法被加入到 `request`
事件中。当服务器接收到 http 请求时，`request` 事件被触发，然后调用 `handleRequest` 方法。

`handleRequest` 方法又调用了 `this.handleRequest(ctx, fn)`：

```javascript
handleRequest(ctx, fnMiddleware) {
    const res = ctx.res;
    res.statusCode = 404;
    const onerror = err => ctx.onerror(err); // koa 默认的错误处理回调函数，处理异常结束
    const handleResponse = () => respond(ctx); // 处理 response 的回调函数
    onFinished(res, onerror); // 监听 http response 的结束事件，执行 onerror 回调函数
    return fnMiddleware(ctx).then(handleResponse).catch(onerror); // 执行中间件，
}
```

`fnMiddleware` 就是这里 `const fn = compose(this.middleware);` 的 `fn`，再看 fn 的实现：

```javascript
function (context, next) {
    // last called middleware #
    let index = -1 // 防止 next 多次调用
    return dispatch(0) // 递归调用中间件
    function dispatch (i) {
        if (i <= index) return Promise.reject(new Error('next() called multiple times'))
        index = i // 从 0 开始，递归调用时加 1
        let fn = middleware[i]
        if (i === middleware.length) fn = next // 注意 fnMiddleware(ctx).then(handleResponse).catch(onerror) 调用时，
                                               // 没有传入 next，所以，这里执行完最后一个中间件后，fn 被赋值了 undefined
        if (!fn) return Promise.resolve() // 立即返回处于 Promise.resolve 状态实例，继续执行后面的逻辑
        try {
            // 用 Promise 包裹中间件，方便 await 调用
            // dispatch.bind(null, i + 1) 是下一个中间件，被当做 next 参数，传入了当前中间件
            // 这就是在中间件执行 next() 的时候就会进入下一个中间件的原理
            return Promise.resolve(fn(context, dispatch.bind(null, i + 1)));
        } catch (err) {
            return Promise.reject(err)
        }
    }
}
```

上面的代码就是 koa 中间件洋葱模型的实现。

![](/images/koa2-analysis/onion.png)

洋葱模型是中间件的一种串行机制，并且是支持异步，第一个中间件中执行 `next()`，则会进入下一个中间件。

官方的中间件示例：

```javascript
// logger
app.use(async (ctx, next) => {
  await next();
  const rt = ctx.response.get('X-Response-Time');
  console.log(`${ctx.method} ${ctx.url} - ${rt}`);
});

// x-response-time
app.use(async (ctx, next) => {
  const start = Date.now();
  await next();
  const ms = Date.now() - start;
  ctx.set('X-Response-Time', `${ms}ms`);
});
```

上面示例中 logger 中间件，调用了 `await next();` 进入了 `x-response-time` 中间件中，`next()` （这里的 `next` 就是 `x-response-time` 中间件）执行完，
则继续执行下面的代码，获取 `X-Response-Time` 并打印日志。

## context.js

Context 包含了两个部分：

- 自身属性，框架内部使用
- 通过 delegates 库，代理了 request, response 对象上的属性。

`application.js` 的 `createContext` 方法创建 ctx 对象：

```javascript
createContext(req, res) {
    const context = Object.create(this.context);
    const request = context.request = Object.create(this.request);
    const response = context.response = Object.create(this.response);
    context.app = request.app = response.app = this;
    context.req = request.req = response.req = req;
    context.res = request.res = response.res = res;
    request.ctx = response.ctx = context;
    request.response = response;
    response.request = request;
    context.originalUrl = request.originalUrl = req.url;
    context.state = {};
    return context;
}
```

```javascript
/**
 * Response delegation.
 */

delegate(proto, 'response')
  .method('attachment')
  .method('redirect')
  .method('remove')
  .method('vary')
  .method('has')
  .method('set')
  .method('append')
  .method('flushHeaders')
  .access('status')
  .access('message')
  .access('body')
  .access('length')
  .access('type')
  .access('lastModified')
  .access('etag')
  .getter('headerSent')
  .getter('writable');

/**
 * Request delegation.
 */

delegate(proto, 'request')
  .method('acceptsLanguages')
  .method('acceptsEncodings')
  .method('acceptsCharsets')
  .method('accepts')
  .method('get')
  .method('is')
  .access('querystring')
  .access('idempotent')
  .access('socket')
  .access('search')
  .access('method')
  .access('query')
  .access('path')
  .access('url')
  .access('accept')
  .getter('origin')
  .getter('href')
  .getter('subdomains')
  .getter('protocol')
  .getter('host')
  .getter('hostname')
  .getter('URL')
  .getter('header')
  .getter('headers')
  .getter('secure')
  .getter('stale')
  .getter('fresh')
  .getter('ips')
  .getter('ip');
```

上面的代码通过 [`delegate`](https://github.com/tj/node-delegates) 代理了 `ctx.request` 和 `ctx.response` 两个对象上的属性。
也就是说，你可以直接通过访问 `ctx.status` 来得到 `ctx.repsponse.status` 的值。

## request.js、response.js

这两部分就是对原生的 http 模块 request、response 对象进行了封装，在对象属性上添加了 setter 和 getter。暴露了一些新的方法。

## 错误处理

koa 有两个 onerror 方法，一个是 Application 的，监听整个应用的 error 事件。一个是 Context 对象的 onerror，监听处理 http request
和 response 时的 error 事件。

`application.js` 的 `onerror`：

```javascript
onerror(err) {
    // 判断是否是 Error 类型
    if (!(err instanceof Error)) throw new TypeError(util.format('non-error thrown: %j', err));
    // 忽略 404 错误
    if (404 == err.status || err.expose) return;
    // 如果有静默设置, 则忽略
    if (this.silent) return;
    // 打印 error
    const msg = err.stack || err.toString();
    console.error();
    console.error(msg.replace(/^/gm, '  '));
    console.error();
}
```

`application.js` 的 `callback` 方法中有段代码：`if (!this.listenerCount('error')) this.on('error', this.onerror);`，如果开
发者没有调用 `app.on('error', func)`监听 error 事件，那么就会在这里添加默认的 `onerror` 回调来监听 error 事件。

`context.js` 的 `onerror`：

```javascript
onerror(err) {
    // don't do anything if there is no error.
    // this allows you to pass `this.onerror`
    // to node-style callbacks.
    if (null == err) return;
    // 将错误转化 Error 类型
    if (!(err instanceof Error)) err = new Error(util.format('non-error thrown: %j', err));

    let headerSent = false;
    if (this.headerSent || !this.writable) {
      headerSent = err.headerSent = true;
    }

    // delegate
    // 触发 koa app 对象的 error 事件, application 上的 onerror 函数会执行
    this.app.emit('error', err, this);

    // nothing we can do here other
    // than delegate to the app-level
    // handler and log.
   // 如果响应头部已经发送(或者 socket 不可写), 退出函数
    if (headerSent) {
      return;
    }
    // 获取原生 http response 对象
    const { res } = this;

    // first unset all headers
    /* istanbul ignore else */
    if (typeof res.getHeaderNames === 'function') {
      res.getHeaderNames().forEach(name => res.removeHeader(name));
    } else {
      res._headers = {}; // Node < 7.7
    }

    // then set those specified
    this.set(err.headers);

    // force text/plain
    // 出错后响应类型为 text/plain
    this.type = 'text';

    // ENOENT support
    // 对 ENOENT 错误进行处理, ENOENT 的错误 message 是文件或者路径不存在, 所以状态码应该是 404
    if ('ENOENT' == err.code) err.status = 404;

    // default to 500
     // 默认状态码为 500
    if ('number' != typeof err.status || !statuses[err.status]) err.status = 500;

    // respond
    const code = statuses[err.status];
    const msg = err.expose ? err.message : code;
    // 设置响应状态码
    this.status = err.status;
     // 设置响应 body 长度
    this.length = Buffer.byteLength(msg);
    // 响应结束
    res.end(msg);
}
```

`application.js` 的 `handleRequest` 方法：

```javascript
handleRequest(ctx, fnMiddleware) {
    const res = ctx.res;
    res.statusCode = 404;
    const onerror = err => ctx.onerror(err);
    const handleResponse = () => respond(ctx);
    onFinished(res, onerror);
    return fnMiddleware(ctx).then(handleResponse).catch(onerror);
}
```

在 `onFinish` 函数中会调用 `context` 的 `onerror` 方法，来处理响应中的 error 事件。

## koa-router

koa 本身并没有实现 router 的功能。需要引入插件。我们通过的 [koa-router](https://github.com/ZijianHe/koa-router) 的官方示例，来分析
一下路由是如何注册并执行的：

```javascript
var Koa = require('koa');
var Router = require('koa-router');

var app = new Koa();
var router = new Router();

// use middleware only with given path
router.use('/users', userAuth());

// or with an array of paths
router.use(['/users', '/admin'], userAuth());

router.get('/', (ctx, next) => {
  // ctx.router available
});

app
  .use(router.routes())
  .use(router.allowedMethods());
```

koa-router 实现路由的核心文件是 `router.js`。`router.js` 也是入口文件。

Router 的构造函数：

```javascript
function Router(opts) {
  if (!(this instanceof Router)) {
    return new Router(opts);
  }

  this.opts = opts || {};
  this.methods = this.opts.methods || [ // 路由方法
    'HEAD',
    'OPTIONS',
    'GET',
    'PUT',
    'PATCH',
    'POST',
    'DELETE'
  ];

  this.params = {};
  this.stack = []; // 存放注册的路由对象
};
```

`router.js` 中定义 `router.get` 或者 `router.post` 等方法：

```javascript
// 遍历所有的 method
methods.forEach(function (method) {
 // 添加原型方法
  Router.prototype[method] = function (name, path, middleware) {
    var middleware;
    // 处理参数，第一个参数可以是路由 name，也可以是路由的 path
    if (typeof path === 'string' || path instanceof RegExp) {
      middleware = Array.prototype.slice.call(arguments, 2);
    } else {
      middleware = Array.prototype.slice.call(arguments, 1);
      path = name;
      name = null;
    }
    // 注册路由，这里的第二个参数是一个数组，是为了 all 方法注册时使用
    this.register(path, [method], middleware, {
      name: name
    });

    return this;
  };
});
```

所以调用 `router.get` 等方法（包括 `router.all` 和 `router.use`）注册路由是其实是调用了 `register` 方法：

```javascript
Router.prototype.register = function (path, methods, middleware, opts) {
  opts = opts || {};

  var router = this;
  var stack = this.stack;

  // support array of paths
  if (Array.isArray(path)) {
    // 如果 path 是一个数组，遍历所有 path，分别为每一个 path 注册路由
    path.forEach(function (p) {
      router.register.call(router, p, methods, middleware, opts);
    });

    return this;
  }

  // create route
  // 创建路由对象
  var route = new Layer(path, methods, middleware, {
    end: opts.end === false ? opts.end : true,
    name: opts.name,
    sensitive: opts.sensitive || this.opts.sensitive || false,
    strict: opts.strict || this.opts.strict || false,
    prefix: opts.prefix || this.opts.prefix || "",
    ignoreCaptures: opts.ignoreCaptures
  });

  // 添加路由前缀
  if (this.opts.prefix) {
    route.setPrefix(this.opts.prefix);
  }

  // add parameter middleware
  // // 设置 param 前置处理函数
  Object.keys(this.params).forEach(function (param) {
    route.param(param, this.params[param]);
  }, this);

  // 存储路由对象
  stack.push(route);

  return route;
};
```

注册完路由，必须通过 `app.use(router.routes())` 方法将所有的路由，添加到 koa 的中间件，`router.routes()` 方法做了什么：

```javascript
Router.prototype.routes = Router.prototype.middleware = function () {
  var router = this;
  // 有点似曾相识，类似 compose 的实现
  var dispatch = function dispatch(ctx, next) {
    debug('%s %s', ctx.method, ctx.path);

    var path = router.opts.routerPath || ctx.routerPath || ctx.path;
    // 匹配路由
    var matched = router.match(path, ctx.method);
    var layerChain, layer, i;
    // 将匹配的路由缓存到 context 对象
    if (ctx.matched) {
      ctx.matched.push.apply(ctx.matched, matched.path);
    } else {
      ctx.matched = matched.path;
    }

    ctx.router = router;

    if (!matched.route) return next(); // // 未匹配到路由，执行下一个中间件

    var matchedLayers = matched.pathAndMethod
    var mostSpecificLayer = matchedLayers[matchedLayers.length - 1]
    ctx._matchedRoute = mostSpecificLayer.path;
    if (mostSpecificLayer.name) {
      ctx._matchedRouteName = mostSpecificLayer.name;
    }
    // 路由的前置处理中间件 将 params、路由别名以及捕获数组属性挂载到 context 上下文对象中
    layerChain = matchedLayers.reduce(function(memo, layer) {
      // 将所有的 layer 封装成了 koa 的中间件函数
      memo.push(function(ctx, next) {
        ctx.captures = layer.captures(path, ctx.captures);
        ctx.params = layer.params(path, ctx.captures, ctx.params);
        ctx.routerName = layer.name;
        // 进入下一个路由中间件
        return next();
      });
      return memo.concat(layer.stack);
    }, []);

    // 返回了 compose 函数，这个函数也同样式依赖 `koa-compose`
    // 将所有匹配的路由 和 路由中间件的数组传入，并执行 compose 返回的函数
    // 注意 koa 是在 `application.js` 的 `callback` 方法中执行 compose 返回的函数
    // 这里利用 compose 函数，又实现了一个洋葱模型
    return compose(layerChain)(ctx, next);
  };

  dispatch.router = this;

  return dispatch;
};
```

`routes` 方法返回了 `dispatch` 函数。`dispatch` 函数被注册到了 koa 的中间件，那么按照 koa 中间件的执行机制，`dispatch` 函数
最终会在某个 koa 中间件中执行 `next` 时被执行。

`router.match` 的实现：

```javascript
Router.prototype.match = function (path, method) {
  var layers = this.stack;
  var layer;
  var matched = {
    path: [],
    pathAndMethod: [],
    route: false
  };
  // 遍历所有存放的路由数组
  for (var len = layers.length, i = 0; i < len; i++) {
    layer = layers[i];

    debug('test %s %s', layer.path, layer.regexp);
    // 调用路由对象 layer 的 math 函数，就是一个正则匹配
    // 将匹配到的 layer 放到 matched.path 数组
    if (layer.match(path)) {
      matched.path.push(layer);
      // layer 的 methods 数组存放的是注册的路由方法
      // 如果 layer.methods.length === 0 该 layer 为路由级别的中间件，即 route.use 方法注册的路由函数
      // ~layer.methods.indexOf(method) -1 按位取反是 00000000，所以这个是判断路由方法被匹配到
      if (layer.methods.length === 0 || ~layer.methods.indexOf(method)) {
        matched.pathAndMethod.push(layer);
       // 当路由的路径和路由方法都被满足时，才算是路由被匹配到，将 matched.route 置为 true
        if (layer.methods.length) matched.route = true;
      }
    }
  }

  return matched;
};
```

```javascript
function Layer(path, methods, middleware, opts) {
  this.opts = opts || {};
  this.name = this.opts.name || null;
  this.methods = [];
  this.paramNames = [];
  this.stack = Array.isArray(middleware) ? middleware : [middleware];

  methods.forEach(function(method) {
    var l = this.methods.push(method.toUpperCase());
    if (this.methods[l-1] === 'GET') {
      this.methods.unshift('HEAD');
    }
  }, this);

  // ensure middleware is a function
  this.stack.forEach(function(fn) {
    var type = (typeof fn);
    if (type !== 'function') {
      throw new Error(
        methods.toString() + " `" + (this.opts.name || path) +"`: `middleware` "
        + "must be a function, not `" + type + "`"
      );
    }
  }, this);

  this.path = path;
  this.regexp = pathToRegExp(path, this.paramNames, this.opts);

  debug('defined route %s %s', this.methods, this.opts.prefix + this.path);
};
```
