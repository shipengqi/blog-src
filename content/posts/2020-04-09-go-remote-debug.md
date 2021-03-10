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

进程会 pending 在这里，等待 remote debug 的连接。

如果不需要被阻塞，可以使用 `--continue` 参数：

```bash
$ dlv --listen=:2345 --headless=true --api-version=2 --accept-multiclient --check-go-version=false exec --continue ./main
API server listening at: [::]:2345
[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:   export GIN_MODE=release
 - using code:  gin.SetMode(gin.ReleaseMode)

...
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

可以设置 `--security-opt=seccomp:unconfined` 参数。关闭容器的 seccomp（linux 内核的一种安全机制） 限制。

docker 是使用命名空间进行用户隔离，使用 cgroups 来限制容器使用的资源。使用 apparmor 限制容器对资源的访问以及使用 seccomp 限制容器的系统调用等。

```bash
$ docker run -p 2345:2345 --security-opt=seccomp:unconfined test:latest

# 或者
$ docker run -p 2345:2345 --security-opt=apparmor:unconfined --cap-add=SYS_PTRACE test:latest
```

`--cap-add` 用来添加 Linux capabilities。`SYS_PTRACE` 表示使用 ptrace(2) 追踪任意进程。

参考：

- [docker run reference](https://docs.docker.com/engine/reference/run/)
- [operation not permitted issue](https://github.com/go-delve/delve/issues/515#issuecomment-214911481)。
- [Delve debug in docker](https://github.com/go-delve/delve/issues/1109)。  
- [container debug](https://github.com/dlsniper/webinar/blob/master/container-debug.sh#L10-L11)。

### closed network connection

如果使用了 `--continue` 参数，碰到了如下错误：
```bash
2021-03-10T07:10:48Z error layer=rpc writing response:write tcp 127.0.0.1:2345->127.0.0.1:39402: use of closed network connection
```

可能是在你的 main goroutine 中有无限循环导致，例如：

```go
func main() {
    for {
        // Necessary code here
    }
}()
```

可以改成：

```go
func main() {
	go func() {
        for {
            // Necessary code here
        }
    }
}()
```

如果要实现在 main goroutine 中阻塞，可以利用 chan 来实现。

参考 [closed network connection issue](https://github.com/go-delve/delve/issues/2284)。

###  permission denied

如果在 kubernetes 中，pod 启动时碰到下面的错误：

```bash
Could not create config directory: mkdir .config: permission denied.
```

可能是因为设置了 securityContext 的问题，可以查看是否配置了 `runAsUser`，`runAsGroup` 等。

另外 pod 也需要配置容器的 `--security-opt` 等参数：

```yaml
    spec:
      containers:
      - args:
        - --security-opt=seccomp:unconfined
        - --security-opt=apparmor:unconfined
        - --cap-add=SYS_PTRACE
# or capabilities in container.securityContext
      securityContext:
        capabilities:
          add:
          - SYS_PTRACE

```

### Kubernetes 中的 Pod 状态 Pending 或者 1/2 Running

在 Kubernetes 中调试时，如果 pod 配置了 `readinessProbe`，但是没有使用 `--continue` 参数，那么容器进程阻塞，会导致 pod 的 `readinessProbe`
总是失败，导致 Pod 的状态一直是 `Pending` 或者 `1/2  Running`。