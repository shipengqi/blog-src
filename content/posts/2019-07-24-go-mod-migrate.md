---
title: Go 项目迁移到 mod
date: 2019-07-24 10:03:52
categories: ["Go"]
---

golang 1.11 已经支持 Go Module。这是官方提倡的新的包管理，乃至项目管理机制，可以不再需要 `GOPATH` 的存在。

## Module 机制

Go Module 不同于以往基于 `GOPATH` 和 Vendor 的项目构建，其主要是通过 `$GOPATH/pkg/mod` 下的缓存包来对项目进行构建。 Go Module 可以通过 `GO111MODULE`
来控制是否启用，`GO111MODULE` 有三种类型:

- `on` 所有的构建，都使用 Module 机制
- `off` 所有的构建，都不使用 Module 机制，而是使用 `GOPATH` 和 Vendor
- `auto` 在 GOPATH 下的项目，不使用 Module 机制，不在 `GOPATH` 下的项目使用

### 和 dep 的区别

- dep 是解析所有的包引用，然后在 `$GOPATH/pkg/dep` 下进行缓存，再在项目下生成 vendor，然后基于 vendor 来构建项目，无法脱离 `GOPATH`。
- mod 是解析所有的包引用，然后在 `$GOPATH/pkg/mod` 下进行缓存，直接基于缓存包来构建项目，所以可以脱离 `GOPATH`

## 准备环境

- golang 1.11 的环境需要开启 `GO11MODULE` ，并且**确保项目目录不在 `GOPATH` 中**。

```sh
export GO111MODULE=on
```

- golang 1.12只需要确保实验目录不在 `GOPATH` 中。
- 配置代理 `export GOPROXY=https://goproxy.io`。（如果拉取包失败，会报  `cannot find module for path xxx` 的错误）

## 迁移项目

```sh
# clone 项目, 不要在 `GOPATH` 中, 之前的项目的结构是 `GOPATH/src/cdf-mannager`
git clone https://github.com/xxx/cdf-mannager

# 删除 vender
cd cdf-mannager
rm -rf vender

# init
go mod init cdf-mannager

# 下载依赖 也可以不执行这一步， go run 或 go build 会自动下载
go mod download
```

Go 会把 `Gopkg.lock` 或者 `glide.lock` 中的依赖项写入到 `go.mod` 文件中。`go.mod` 文件的内容像下面这样：

```
module cdf-manager

require (
        github.com/fsnotify/fsnotify v1.4.7
        github.com/gin-contrib/sse v0.0.0-20170109093832-22d885f9ecc7
        github.com/gin-gonic/gin v0.0.0-20180814085852-b869fe1415e4
        github.com/golang/protobuf v0.0.0-20170601230230-5a0f697c9ed9
        github.com/hashicorp/hcl v1.0.0
        github.com/inconshreveable/mousetrap v0.0.0-20141017200713-76626ae9c91c
        github.com/json-iterator/go v0.0.0-20170829155851-36b14963da70
        github.com/lexkong/log v0.0.0-20180607165131-972f9cd951fc
        github.com/magiconair/properties v1.8.0
        github.com/mattn/go-isatty v0.0.0-20170307163044-57fdcb988a5c
        github.com/mitchellh/mapstructure v1.1.2
        github.com/pelletier/go-toml v1.2.0
        github.com/satori/go.uuid v0.0.0-20180103152354-f58768cc1a7a
        github.com/spf13/afero v1.1.2
        github.com/spf13/cast v1.3.0
        github.com/spf13/cobra v0.0.0-20180427134550-ef82de70bb3f
        github.com/spf13/jwalterweatherman v1.0.0
        github.com/spf13/pflag v1.0.3
        github.com/spf13/viper v0.0.0-20181207100336-6d33b5a963d9
        github.com/ugorji/go v1.1.2-0.20180831062425-e253f1f20942
        github.com/willf/pad v0.0.0-20160331131008-b3d780601022
        golang.org/x/sys v0.0.0-20190116161447-11f53e031339
        golang.org/x/text v0.3.0
        gopkg.in/go-playground/validator.v8 v8.0.0-20160718134125-5f57d2222ad7
        gopkg.in/yaml.v2 v2.2.2
)

```

**如果是一个新项目，或者删除了 `Gopkg.lock` 文件，可以直接运行：**

```sh
go mod init cdf-mannager

# 拉取必须模块 移除不用的模块
go mod tidy
```

接下来就可以运行 `go run main.go` 了。

## 添加新依赖包

添加新依赖包有下面几种方式：

1. 直接修改 `go.mod` 文件，然后执行 `go mod download`。
2. 使用 `go get packagename@vx.x.x`，会自动更新 `go.mod` 文件的。
3. `go run`、`go build` 也会自动下载依赖。

## 依赖包冲突问题

迁移后遇到了下面的报错：

```sh
../gowork/pkg/mod/github.com/gin-gonic/gin@v0.0.0-20180814085852-b869fe1415e4/binding/msgpack.go:12:2: unknown import path "github.com/ugorji/go/codec": ambiguous import: found github.com/ugorji/go/codec in multiple modules:
 github.com/ugorji/go v0.0.0-20170215201144-c88ee250d022 (/root/gowork/pkg/mod/github.com/ugorji/go@v0.0.0-20170215201144-c88ee250d022/codec)
 github.com/ugorji/go/codec v0.0.0-20181204163529-d75b2dcb6bc8 (/root/gowork/pkg/mod/github.com/ugorji/go/codec@v0.0.0-20181204163529-d75b2dcb6bc8)
```

通过 `go mod graph` 可以查看具体依赖路径：

```sh
github.com/spf13/viper@v1.3.2 github.com/ugorji/go/codec@v0.0.0-20181204163529-d75b2dcb6bc8
github.com/gin-gonic/gin@v1.3.1-0.20190120102704-f38a3fe65f10 github.com/ugorji/go@v1.1.1
```

可以看到 `viper` 和 `gin` 分别依赖了 `github.com/ugorji/go` 和 `github.com/ugorji/go/codec`。

应该是 `go` 把这两个 `path` 当成不同的模块引入导致的冲突。[workaround](https://github.com/ugorji/go/issues/279)。
