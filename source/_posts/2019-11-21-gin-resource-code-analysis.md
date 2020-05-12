---
title: Gin 框架源码分析
date: 2019-11-21 17:22:16
tags:
---


[Gin](https://github.com/gin-gonic/gin) 是基于 Golang 实现的的一个 web 框架。Gin 是一个类似于 [martini](https://github.com/go-martini/martini) 
但拥有更好性能的 API 框架, 由于 [httprouter](https://github.com/julienschmidt/httprouter)，速度提高了近 40 倍。

## Handler 接口的实现
我们从一个官方示例开始，来分析 Gin 的实现原理：
```go
package main

import "github.com/gin-gonic/gin"

func main() {
    // 常见一个 gin 默认实例
	r := gin.Default()
    // 注册路由
	r.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})
	r.Run() // 监听并在 0.0.0.0:8080 上启动服务
}
```
`gin.Default()` 创建了一个 gin 默认的 `Engine` 实例，`Engine` 的结构：
```go
// Engine is the framework's instance, it contains the muxer, middleware and configuration settings.
// Create an instance of Engine, by using New() or Default()
type Engine struct {
    // 继承了 RouterGroup，比如 GET, POST 等路由方法
	RouterGroup // 路由组
    ...
	pool             sync.Pool // 存放 context 对象
	trees            methodTrees // 存放所有的路由处理函数
}
```
`Engine` 结构体，有三个比较重要的属性。
 
```go
func New() *Engine {
	debugPrintWARNINGNew()
	engine := &Engine{
		RouterGroup: RouterGroup{ // 初始化 RouterGroup
			Handlers: nil,
			basePath: "/",
			root:     true,       // root 的 RouterGroup
		},
		FuncMap:                template.FuncMap{},
		RedirectTrailingSlash:  true,
		RedirectFixedPath:      false,
		HandleMethodNotAllowed: false,
		ForwardedByClientIP:    true,
		AppEngine:              defaultAppEngine,
		UseRawPath:             false,
		UnescapePathValues:     true,
		MaxMultipartMemory:     defaultMultipartMemory,
		trees:                  make(methodTrees, 0, 9),
		delims:                 render.Delims{Left: "{{", Right: "}}"},
		secureJsonPrefix:       "while(1);",
	}
	engine.RouterGroup.engine = engine // 将 engine 实例添加到了 RouterGroup.engine 上，方便调用
	                                   // 比如：
	                                   //     路由分组函数 group.Group() 会用到
	                                   //     group.handle() 添加路由时，最终也是调用的 engine.addRoute 将路由添加到 engine.trees
    // 创建 pool 来存放 context
	engine.pool.New = func() interface{} {
		return engine.allocateContext()
	}
	return engine
}

// Default returns an Engine instance with the Logger and Recovery middleware already attached.
func Default() *Engine {
	debugPrintWARNINGDefault()
    // 调用 New 方法创建 engine 实例
	engine := New()
    // 默认实例 添加了 Logger 和 Recovery 中间件
	engine.Use(Logger(), Recovery())
	return engine
}
```


接着从 `Run` 方法的实现开始分析： 
```go
// Run attaches the router to a http.Server and starts listening and serving HTTP requests.
// It is a shortcut for http.ListenAndServe(addr, router)
// Note: this method will block the calling goroutine indefinitely unless an error happens.
func (engine *Engine) Run(addr ...string) (err error) {
	defer func() { debugPrintError(err) }()
    // 解析传入的地址
	address := resolveAddress(addr)
	debugPrint("Listening and serving HTTP on %s\n", address)
    // 监听 address，启动服务，
	err = http.ListenAndServe(address, engine)
	return
}
```

`Run` 方法其实就是对标准库 http 包的 `ListenAndServe` 方法进行了封装。重点就是 `ListenAndServe` 方法的第二个参数， 这里的 `engine`
就是 gin 实例。`ListenAndServe` 方法的第二个参数是一个 `Handler` 接口类型。`Handler` 接口是用来响应 HTTP 请求的，最终 HTTP 服务会调用
`Handler` 接口的 `ServeHTTP(ResponseWriter, *Request)` 方法来处理客户端请求并响应。

gin 实例的 `Handler` 接口实现：
```go
// ServeHTTP conforms to the http.Handler interface.
func (engine *Engine) ServeHTTP(w http.ResponseWriter, req *http.Request) {
    // 使用 sync.Pool 缓存 context 对象，避免重复创建对象，减轻 GC 的消耗
    // 从 pool 中获取一个 context
	c := engine.pool.Get().(*Context)
    // 重置 context 实例的 http.ResponseWriter
	c.writermem.reset(w)
    // 重置 context 实例的 *http.Request
	c.Request = req
    // 重置 context 实例的一些其他属性
	c.reset()
    // 处理请求，context 实例为参数传入
	engine.handleHTTPRequest(c)

    // 将 context 对象放回 pool
	engine.pool.Put(c)
}
```

`engine.handleHTTPRequest(c)` 是 gin 处理请求的方法：
```go
func (engine *Engine) handleHTTPRequest(c *Context) {
	httpMethod := c.Request.Method
	rPath := c.Request.URL.Path
	unescape := false
	if engine.UseRawPath && len(c.Request.URL.RawPath) > 0 {
		rPath = c.Request.URL.RawPath
		unescape = engine.UnescapePathValues
	}
    // 获取请求的 path
	rPath = cleanPath(rPath)

	// Find root of the tree for the given HTTP method
	t := engine.trees
	for i, tl := 0, len(t); i < tl; i++ {
        // 匹配请求的 method
		if t[i].method != httpMethod {
			continue
		}
        // 获取匹配到的 method 的 root 节点
		root := t[i].root
		// Find route in tree
        // 根据请求的 path，参数，找到对应的路由处理函数
		value := root.getValue(rPath, c.Params, unescape)
		if value.handlers != nil {
            // 更新 context 对象，将所有匹配的 handlers 路由函数缓存到 context 对象
			c.handlers = value.handlers
			c.Params = value.params
			c.fullPath = value.fullPath
            // 执行 handlers
			c.Next()
            // 处理 response
			c.writermem.WriteHeaderNow()
			return
		}
		if httpMethod != "CONNECT" && rPath != "/" {
			if value.tsr && engine.RedirectTrailingSlash {
				redirectTrailingSlash(c)
				return
			}
			if engine.RedirectFixedPath && redirectFixedPath(c, root, engine.RedirectFixedPath) {
				return
			}
		}
		break
	}

	if engine.HandleMethodNotAllowed {
		for _, tree := range engine.trees {
			if tree.method == httpMethod {
				continue
			}
			if value := tree.root.getValue(rPath, nil, unescape); value.handlers != nil {
				c.handlers = engine.allNoMethod
				serveError(c, http.StatusMethodNotAllowed, default405Body)
				return
			}
		}
	}
	c.handlers = engine.allNoRoute
	serveError(c, http.StatusNotFound, default404Body)
}
```

`c.Next()` 是最终执行路由处理函数的地方：
```go
// Next should be used only inside middleware.
// It executes the pending handlers in the chain inside the calling handler.
// See example in GitHub.
func (c *Context) Next() {
    // c.index 的值在 c.reset() 方法中被重置为 -1 了，也就是从 0 开始遍历 handlers 数组
	c.index++
	for c.index < int8(len(c.handlers)) {
        // 遍历所有的 handlers，包括中间件 和 路由处理函数
		c.handlers[c.index](c) // 执行 handler
		c.index++
	}
}
```

## 注册中间件
gin 注册中间的方法 `engine.Use`：
```go
// Use attaches a global middleware to the router. ie. the middleware attached though Use() will be
// included in the handlers chain for every single request. Even 404, 405, static files...
// For example, this is the right place for a logger or error management middleware.
func (engine *Engine) Use(middleware ...HandlerFunc) IRoutes {
    // 调用 RouterGroup 的 Use 方法，注册中间件
	engine.RouterGroup.Use(middleware...)
	engine.rebuild404Handlers()
	engine.rebuild405Handlers()
	return engine
}

// RouterGroup 的 Use 方法
// Use adds middleware to the group, see example code in GitHub.
func (group *RouterGroup) Use(middleware ...HandlerFunc) IRoutes {
    // 合并所有的中间件 handlers
	group.Handlers = append(group.Handlers, middleware...)
	return group.returnObj()
}
```

上面的代码可以看出 `engine.Use()` 方法把所有的中间件添加到了一个全局的 `Handlers` 数组中。

##　注册路由
路由是如何被添加到 `engine.trees` 的？以示例中 `r.GET("/ping", func)` 为例，`engine` 的 `GET` 方法是继承自 `RouterGroup` 的：
```go
// GET is a shortcut for router.Handle("GET", path, handle).
func (group *RouterGroup) GET(relativePath string, handlers ...HandlerFunc) IRoutes {
	return group.handle("GET", relativePath, handlers)
}
```
其他路由方法也是类似的实现（如 `POST`，`DELETE`），调用 `group.handle` 来添加路由。

```go
func (group *RouterGroup) handle(httpMethod, relativePath string, handlers HandlersChain) IRoutes {
	absolutePath := group.calculateAbsolutePath(relativePath)
    // 把中间件的 handlers 和对应路由的 handlers 合并
	handlers = group.combineHandlers(handlers)
    // 将合并的 handlers 集合，注册到 engine.trees，group.engine 在 New() 的时候已经赋值
	group.engine.addRoute(httpMethod, absolutePath, handlers)
	return group.returnObj()
}

func (group *RouterGroup) combineHandlers(handlers HandlersChain) HandlersChain {
    // Use() 方法将所有的中间件都存放在了 group.Handlers 数组中
    // 所以这里计算的是 中间件 handlers 和 路由 handlers 的总数
	finalSize := len(group.Handlers) + len(handlers)
    // 注册的中间件 handlers 和 路由 handlers 总数不能超过 abortIndex
	if finalSize >= int(abortIndex) {
		panic("too many handlers")
	}
	mergedHandlers := make(HandlersChain, finalSize)
    // 将中间件 handlers 和 路由 handlers 拷贝到一个新的切片
	copy(mergedHandlers, group.Handlers)
	copy(mergedHandlers[len(group.Handlers):], handlers)
	return mergedHandlers
}

func (engine *Engine) addRoute(method, path string, handlers HandlersChain) {
    // 路由校验
	assert1(path[0] == '/', "path must begin with '/'")
	assert1(method != "", "HTTP method can not be empty")
	assert1(len(handlers) > 0, "there must be at least one handler")

	debugPrintRoute(method, path, handlers)
    // 遍历 trees 数组，获取 method 的路由的 root 节点
    // 这里 trees 的数据结构并没有使用 map，可能是觉得 method 没几个，遍历也无所谓
	root := engine.trees.get(method)
	if root == nil { // 如果没有，就创建路由的 root 节点
		root = new(node)
		root.fullPath = "/"
		engine.trees = append(engine.trees, methodTree{method: method, root: root})
	}
    // 将 handlers 集合添加到 root.handlers
	root.addRoute(path, handlers)
}
```

### 路由组
gin 可以添加路由组，比如：
```go
func main() {
	router := gin.Default()

	// 简单的路由组: v1
	v1 := router.Group("/v1")
	{
		v1.POST("/login", loginEndpoint)
		v1.POST("/submit", submitEndpoint)
		v1.POST("/read", readEndpoint)
	}

	// 简单的路由组: v2
	v2 := router.Group("/v2")
	{
		v2.POST("/login", loginEndpoint)
		v2.POST("/submit", submitEndpoint)
		v2.POST("/read", readEndpoint)
	}

	router.Run(":8080")
}
```

```go
// Group creates a new router group. You should add all the routes that have common middlewares or the same path prefix.
// For example, all the routes that use a common middleware for authorization could be grouped.
func (group *RouterGroup) Group(relativePath string, handlers ...HandlerFunc) *RouterGroup {
	return &RouterGroup{
		Handlers: group.combineHandlers(handlers),
		basePath: group.calculateAbsolutePath(relativePath),
		engine:   group.engine,   // 全局的 engine 实例
	}
}
```

可以看出 `Group()` 虽然返回了一个新的 `RouterGroup` 实例，但是 `engine` 仍然指向了全局唯一的 `engine` 实例。也就意味着 `v1.POST` 和
`v2.POST` 添加的路由 handlers 和 中间件 handlers 最终都添加到了 handlers 树 `engine.trees` 上。

## Next 方法的调用流程
前面已经知道 `engine.handleHTTPRequest` 在路由匹配之后，会调用 `Next` 方法来执行对应的 handlers：
```go
// Next should be used only inside middleware.
// It executes the pending handlers in the chain inside the calling handler.
// See example in GitHub.
func (c *Context) Next() {
    // c.index 的值在 c.reset() 方法中被重置为 -1 了，也就是从 0 开始遍历 handlers 数组
	c.index++
	for c.index < int8(len(c.handlers)) {
        // 遍历所有的 handlers，包括中间件 和 路由处理函数
		c.handlers[c.index](c) // 执行 handler
		c.index++
	}
}
```

上面的代码，`for` 循环遍历 handlers 执行，也就意味着在中间件 handlers 中， `c.Next()` 并不是必须的，根据情况调用。

`Next` 方法可以在中间件函数中主动调用，例如：

```go
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		t := time.Now()

		// 设置 example 变量
		c.Set("example", "12345")

		// 请求前

		c.Next()

		// 请求后
		latency := time.Since(t)
		log.Print(latency)

		// 获取发送的 status
		status := c.Writer.Status()
		log.Println(status)
	}
}

func main() {
	r := gin.New()
	r.Use(Logger())

	r.GET("/test", func(c *gin.Context) {
		example := c.MustGet("example").(string)

		// 打印："12345"
		log.Println(example)
	})

	// 监听并在 0.0.0.0:8080 上启动服务
	r.Run(":8080")
}

```

`Next()` 方法中，使用的 `c.index` 这个成员变量，这个变量相对于整个流程是全局的，这样就可以保证每个 handler 只执行一次。

当在中间件中调用 `c.Next()` 时，这个中间件就得到了控制权，执行 `c.Next()`，`c.index` 先加 1，然后进入 `for` 循环，循环执行结束，控制权还
给 context。这个实现有点类似 [koa](https://github.com/koajs/koa) 的洋葱模型。


## 路由树
gin router 的底层数据结构是**基树**（Radix tree），类似 Trie 树。

![](/images/gin-analysis/radix-tree.png)

Radix tree 的节点：
```go
type node struct {
    // 相对路径
    path      string
    // 索引
    indices   string
    // 子节点
    children  []*node
    // 处理者列表
    handlers  HandlersChain
    priority  uint32
    // 结点类型：static, root, param, catchAll
    nType     nodeType
    // 最多的参数个数
    maxParams uint8
    // 是否是通配符(:param_name | *param_name)
    wildChild bool
    // 完整路径
	fullPath  string
}
```

一个路由示例：
```go
package main

import (
	"fmt"

	"github.com/gin-gonic/gin"
)
func m1(c *gin.Context)  {
	fmt.Println("middleware1")
}

func m2(c *gin.Context)  {
	fmt.Println("middleware2")
}

func f(c *gin.Context)  {
	c.JSON(200, gin.H{
		"message": "ok",
	})
}


func f1(c *gin.Context)  {
	c.JSON(200, gin.H{
		"message": "ok",
	})
}

func f2(c *gin.Context)  {
	c.JSON(200, gin.H{
		"message": "ok",
	})
}

func f3(c *gin.Context)  {
	c.JSON(200, gin.H{
		"message": "ok",
	})
}

func f4(c *gin.Context)  {
	c.JSON(200, gin.H{
		"message": "ok",
	})
}

func main() {
	r := gin.Default()
    r.Get("/", f)
	r.Use(m1)
	r.GET("/index", f1)
	r.GET("/ins", f2)
	r.Use(m2)
	r.GET("/go", f3)
	r.GET("/golang", f4)

	r.Run() // listen and serve on 0.0.0.0:8080 (for windows "localhost:8080")
}
```

上面的示例，生成树结构示意图：
![](/images/gin-analysis/demo-tree.png)
