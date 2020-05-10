---
title: Gin 框架源码分析
tags:
---

[Gin](https://github.com/gin-gonic/gin) 是基于 Golang 实现的的一个 web 框架。Gin 是一个类似于 [martini](https://github.com/go-martini/martini) 
但拥有更好性能的 API 框架, 由于 [httprouter](https://github.com/julienschmidt/httprouter)，速度提高了近 40 倍。

## net/http 标准库分析

## Gin 源码分析

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

我们从 `run` 方法开始分析： 
```go
// Run attaches the router to a http.Server and starts listening and serving HTTP requests.
// It is a shortcut for http.ListenAndServe(addr, router)
// Note: this method will block the calling goroutine indefinitely unless an error happens.
func (engine *Engine) Run(addr ...string) (err error) {
	defer func() { debugPrintError(err) }()
    // 解析传入的地址
	address := resolveAddress(addr)
	debugPrint("Listening and serving HTTP on %s\n", address)
    // 监听 address，启动服务
	err = http.ListenAndServe(address, engine)
	return
}
```

`Run` 方法其实就是对标准库 http 包的 `ListenAndServe` 方法进行了封装。重点就是 `ListenAndServe` 方法的第二个参数， 这里的 `engine`
就是 gin 实例。

`Handler` 接口 `ServeHttp`。

- https://gin-gonic.com/zh-cn/docs/examples/custom-middleware/
- https://www.cnblogs.com/yjf512/p/9670990.html
- https://l1905.github.io/golang%E5%BC%80%E5%8F%91/2019/08/14/golang-http-webserver/
- https://l1905.github.io/golang%E5%BC%80%E5%8F%91/2019/08/14/golang-gin-webserver/
- https://www.jianshu.com/p/dbe8e742513f
- https://www.kancloud.cn/liuqing_will/the_source_code_analysis_of_gin/616924
- http://tigerb.cn/2019/07/06/go-gin/
- https://blog.csdn.net/weixin_41315492/article/details/103909043
- https://www.jianshu.com/p/35addb4de300
