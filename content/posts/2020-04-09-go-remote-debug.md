---
title: Golang Remote Debug with Delve
date: 2020-04-09T17:55:23+08:00
draft: false
---

## Delve 安装

```bash
$ go get github.com/go-delve/delve/cmd/dlv

# or
$ git clone https://github.com/go-delve/delve.git $GOPATH/src/github.com/go-delve/delve
$ cd $GOPATH/src/github.com/go-delve/delve
$ make install

# check
$ dlv version
```

如果找不到 `dlv`，检查环境变量 `PATH` 和 `GOPATH`。

> 如果使用的是 Go Modules，执行上面的命令时，不要在你的项目目录里面。

## 编译源码并开启调试模式

```bash
# compile
CGO_ENABLED=0 go build -gcflags "all=-N -l" -a -o ./main ./main.go

# start
dlv --listen=:2345 \
 --headless=true \
 --api-version=2 \
 --accept-multiclient \
 --check-go-version=false \
 exec ./main
```

`--check-go-version` 的默认值是 `true`，检查 golang 的版本。在有些环境下可以设置为 `false`，比如我是将二进制文件运行在容器环境中，而我的容器
中并没有 golang。

> golang 的版本要大于 1.14。

如果 `./main` 后面需要参数，使用 `--` 分隔，例如：

```bash
$ dlv --listen=:2345 --headless=true --api-version=2 --accept-multiclient --check-go-version=false exec ./main -- -f ./conf/debug.ini
```

相当于：

```bash
$ ./main -f ./conf/debug.ini
```

启动服务之后，输出：

```bash
$ dlv --listen=:2345 --headless=true --api-version=2 --accept-multiclient --check-go-version=false exec ./main
API server listening at: [::]:2345
```

## IDE 配置

示例使用的 IDE 是 IDEA，在 `Add Configuration` 中配置 `Go Remote`：

![ide-go-remote.png](/images/go-remote/ide-go-remote.png)

配置好后，点击 debug 按钮：

![ide-go-start-debug.png](/images/go-remote/ide-go-start-debug.png)

连接成功之后，server 端会输出：

```bash
$ dlv --listen=:2345 --headless=true --api-version=2 --accept-multiclient --check-go-version=false exec ./main
API server listening at: [::]:2345
[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:   export GIN_MODE=release
 - using code:  gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /                         --> suite-installer-backend/app/http.loadRouter.func2 (6 handlers)
[GIN-debug] GET    /healthz                  --> suite-installer-backend/app/http.healthCheck (6 handlers)
[GIN-debug] GET    /urest/v1.2/deployment/:deploymentUuid/components --> suite-installer-backend/app/http.getComponents (7 handlers)
[GIN-debug] POST   /urest/v1.2/deployment/:deploymentUuid/deployer --> suite-installer-backend/app/http.startDeployer (7 handlers)
[GIN-debug] POST   /urest/v1.2/deployment/:deploymentUuid/logs --> suite-installer-backend/app/http.saveLogs (7 handlers)

```

之后就可以断点调试了。

## 问题

### operation not permitted

在 docker container 中运行，如果输出下面的错误：

```bash
could not launch process: fork/exec ./main: operation not permitted
```

可以设置 `--security-opt=seccomp:unconfined` 参数。

参考 [operation not permitted issue](https://github.com/go-delve/delve/issues/515#issuecomment-214911481)。