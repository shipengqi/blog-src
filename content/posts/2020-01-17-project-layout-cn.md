---
title: Go project-layout（翻译）
date: 2020-01-17 16:56:17
categories: ["Go"]
---


标准的 Go 项目布局，[project-layout](https://github.com/golang-standards/project-layout) 翻译。

<!--more-->

这是一个 Go 应用项目的基本布局。它不是官方核心 Go dev 团队定义的标准；然而，它是 GO 生态圈中一套历史上和新兴项目中常见的布局模式。其中
一些模式比其他模式更受欢迎。它还有一些小的增强,以及一些对于任何一个大真实世界应用程序，都通用的支持目录。

如果你正在学习 GO,或者你正在自己创建一个 PoC 或只是简单玩一玩, 那这个项目布局对你来说有点过头了。从简单的东西开始（一个 `main.go` 文件就足够
了）。随着你的项目的发展，确保你的代码结构良好是非常重要的，否则你最终会有很多隐藏的依赖和全局状态的混乱代码。当有更多人在项目上工作时，就需要更多
的结构。这时就需要引入一种通用的方式来管理软件 packages/libraries。当你有一个开源项目，或者其他项目从你的项目库中导入代码时，这时就需要私有
的（`internal`）包和代码。

Clone `project-layout` 仓库, 保留你需要的东西，然后删除所有其他的东西。虽然它在那里，但并不意味着你必须全部使用它。
这些模式并不是在每一个项目都会用到的。即使是 `vendor` 模式也不是万能的。

随着 Go 1.14 版本的发布，[`Go Modules`](https://github.com/golang/go/wiki/Modules) 终于可以用于生产环境了。使用 `Go Modules` 除非
你有特定的理由不使用它。使用 `Go Modules` 就不再需要担心 `$GOPATH` 和项目要放在哪里。

项目中的 `go.mod` 文件会假设你的项目托管在 Github 上，但这并不是必须的。模块路径可以是任何东西，但第一个模块路径组件的名称中应该有一个
点（当前版本的 Go 不再强制要求它，但如果你使用的是稍旧的版本，如果构建失败了，不要惊讶）。如果你想了解更多，可以参
考 issue [`37554`](https://github.com/golang/go/issues/37554) 和 [`32819`](https://github.com/golang/go/issues/32819) 。

这个项目布局是通用为主的，它不试图强加一个特定的 Go 包结构。

如果你在命名、格式化和样式方面需要帮助，可以从运行 [`gofmt`](https://golang.org/cmd/gofmt/) 和
[`golint`](https://github.com/golang/lint) 开始。此外，请务必阅读这些 Go 的代码规范指南和建议。

- <https://talks.golang.org/2014/names.slide>
- <https://golang.org/doc/effective_go.html#names>
- <https://blog.golang.org/package-names>
- <https://github.com/golang/go/wiki/CodeReviewComments>
- [Style guideline for Go packages](https://rakyll.org/style-packages/) (rakyll/JBD)

可以查看 [`Go Project Layout`](https://medium.com/golang-learn/go-project-layout-e5213cdcfaa2) 的历史背景信息。

更多关于命名和组织包以及代码结构的建议：

- [GopherCon EU 2018: Peter Bourgon - Best Practices for Industrial Programming](https://www.youtube.com/watch?v=PTE4VJIdHPg)
- [GopherCon Russia 2018: Ashley McNamara + Brian Ketelsen - Go best practices.](https://www.youtube.com/watch?v=MzTcsI6tn-0)
- [GopherCon 2017: Edward Muller - Go Anti-Patterns](https://www.youtube.com/watch?v=ltqV6pDKZD8)
- [GopherCon 2018: Kat Zien - How Do You Structure Your Go Apps](https://www.youtube.com/watch?v=oL6JBUk6tj0)

## Go 目录

目录结构示例：

```sh
.
├── api
├── assets
├── build
│   ├── ci
│   └── package
├── cmd
│   └── _your_app_
├── configs
├── deployments
├── docs
├── examples
├── githooks
├── init
├── internal
│   ├── app
│   │   └── _your_app_
│   └── pkg
│       └── _your_private_lib_
├── pkg
│   └── _your_public_lib_
├── scripts
├── test
├── third_party
├── tools
├── vendor
├── web
│   ├── app
│   ├── static
│   └── template
├── website
├── README.md
├── LICENSE.md
├── Makefile
├── go.mod
└── .gitignore
```

### `/cmd`

项目中的主要应用程序。

每个应用程序的目录名应该与你想要的可执行文件的名相匹配（例如，`/cmd/myapp`）。

不要在此目录中放置大量代码。如果你认为这个代码可以被其他项目引用，那么它应该存在于 `/pkg` 目录。如果代码不可重用，或者如果不希望其他人重用它，那么将
代码放入 `/internal` 目录。

比较常见的项目，有一个小的 `main` 函数，从 `/internal` 和 `/pkg` 目录中导入并调用代码，其他的都不需要。

例子:

- <https://github.com/heptio/ark/tree/master/cmd> (只是一个非常小的 `main` 函数，其他的东西都在包里)
- <https://github.com/moby/moby/tree/master/cmd>
- <https://github.com/prometheus/prometheus/tree/master/cmd>
- <https://github.com/influxdata/influxdb/tree/master/cmd>
- <https://github.com/kubernetes/kubernetes/tree/master/cmd>

### `/internal`

私有应用程序和库代码。这是你不希望别人在他们的应用程序或库中导入的代码。

注意，这个布局模式是由 Go 编译器本身执行的。更多细节请参见 Go 1.4 [`release notes`](https://golang.org/doc/go1.4#internalpackages) 。
注意，你并不局限于顶层的 `internal` 目录。你可以在你的项目树的任何层级上有一个 `internal` 目录。

> Go 语言的构建工具对包含 `internal` 名字的路径段的包导入路径做了特殊处理。一个 `internal` 包只能被和 `internal` 目录有同一个父目录的
包所导入。例如，`net/http/internal/chunked` 内部包只能被 `net/http/httputil` 或 `net/http` 包导入，但是不能被 `net/url` 包导入。

你可以选择在你的内部包中添加一些额外的结构，将共享和非共享的内部代码分开。这并不是必须的（尤其是对于较小的项目来说），但如果能有可视化的线索显
示出预定的包的用途就很好了。

将实际应用程序代码放入 `/internal/app` 目录(例如，`/internal/app/myapp`。应用程序共享的代码可以放在 `/internal/pkg` 目录(例如，
`/internal/pkg/myprivlib`)。

例子：

- <https://github.com/hashicorp/terraform/tree/master/internal>
- <https://github.com/influxdata/influxdb/tree/master/internal>
- <https://github.com/perkeep/perkeep/tree/master/internal>
- <https://github.com/jaegertracing/jaeger/tree/master/internal>
- <https://github.com/moby/moby/tree/master/internal>
- <https://github.com/satellity/satellity/tree/master/internal>

### `/pkg`

可以被外部应用程序使用的库代码(例如，`/pkg/mypubliclib`)。其他项目将导入这些库，并希望它们能工作，所以在你把东西放在这里之前要三思。

需要注意的是，使用 `internal` 目录来保证你的私有包不能被导入是一个比较好的方法，因为它是由 Go 强制执行的。

`/pkg` 目录中的代码应该是可以被安全的导入使用的。Travis Jeffery 的 blog [`I'll take pkg over internal`](https://travisjeffery.com/b/2019/11/i-ll-take-pkg-over-internal/)
提供了关于 `pkg` 和 `internal` 目录的一个很好的概述，以及什么时候使用它们可能有意义。

如果你的应用程序项目真的很小，而且额外的嵌套不会增加多少价值（除非你真的想用），那就不要用它。当它变得足够大，而你的根目录变得相当繁忙时，再考虑
使用（尤其是当你有很多非 Go 的应用组件时）。

例子：

- <https://github.com/prometheus/prometheus/tree/master/pkg>
- <https://github.com/jaegertracing/jaeger/tree/master/pkg>
- <https://github.com/istio/istio/tree/master/pkg>
- <https://github.com/GoogleContainerTools/kaniko>
- <https://github.com/google/gvisor/tree/master/pkg>
- <https://github.com/google/syzkaller/tree/master/pkg>
- <https://github.com/perkeep/perkeep/tree/master/pkg>
- <https://github.com/minio/minio/tree/master/pkg>
- <https://github.com/heptio/ark/tree/master/pkg>
- <https://github.com/argoproj/argo/tree/master/pkg>
- <https://github.com/heptio/sonobuoy/tree/master/pkg>
- <https://github.com/helm/helm/tree/master/pkg>
- <https://github.com/kubernetes/kubernetes/tree/master/pkg>
- <https://github.com/kubernetes/kops/tree/master/pkg>
- <https://github.com/moby/moby/tree/master/pkg>
- <https://github.com/grafana/grafana/tree/master/pkg>
- <https://github.com/influxdata/influxdb/tree/master/pkg>
- <https://github.com/cockroachdb/cockroach/tree/master/pkg>
- <https://github.com/derekparker/delve/tree/master/pkg>
- <https://github.com/etcd-io/etcd/tree/master/pkg>
- <https://github.com/oklog/oklog/tree/master/pkg>
- <https://github.com/flynn/flynn/tree/master/pkg>
- <https://github.com/jesseduffield/lazygit/tree/master/pkg>
- <https://github.com/gopasspw/gopass/tree/master/pkg>
- <https://github.com/sosedoff/pgweb/tree/master/pkg>
- <https://github.com/GoogleContainerTools/skaffold/tree/master/pkg>
- <https://github.com/knative/serving/tree/master/pkg>
- <https://github.com/grafana/loki/tree/master/pkg>
- <https://github.com/bloomberg/goldpinger/tree/master/pkg>
- <https://github.com/crossplaneio/crossplane/tree/master/pkg>
- <https://github.com/Ne0nd0g/merlin/tree/master/pkg>
- <https://github.com/jenkins-x/jx/tree/master/pkg>
- <https://github.com/DataDog/datadog-agent/tree/master/pkg>
- <https://github.com/dapr/dapr/tree/master/pkg>
- <https://github.com/cortexproject/cortex/tree/master/pkg>
- <https://github.com/dexidp/dex/tree/master/pkg>
- <https://github.com/pusher/oauth2_proxy/tree/master/pkg>
- <https://github.com/pdfcpu/pdfcpu/tree/master/pkg>
- <https://github.com/weaveworks/kured/pkg>
- <https://github.com/weaveworks/footloose/pkg>
- <https://github.com/weaveworks/ignite/pkg>
- <https://github.com/tmrts/boilr/tree/master/pkg>

### `/vendor`

应用程序依赖(手动管理，或你喜欢的依赖管理工具，Go Modules)。 `go mod vendor` 命令将为你创建 `/vendor` 目录。请注意，如果你不是使
用 Go 1.14，你可能需要在你的 `go build` 命令中添加 `-mod=vendor` 标志，因为 Go 1.14 的默认值是 `on`。

如果你正在构建一个库，不要提交你的应用程序依赖项。

注意，从 [`1.13`](https://golang.org/doc/go1.13#modules) 开始，Go 启用了模块代理功能（默认使用 `https://proxy.golang.org` 作为
模块代理服务器）。阅读更多关于它的 [信息](https://blog.golang.org/module-mirror-launch) ，看看它是否符合你的所有要求和限制。如果符合，
那么你就完全不需要 `vendor` 目录了。

## 服务应用目录

### `/api`

OpenAPI/Swagger 规范，JSON schema 文件，协议定义文件。

例子：

- <https://github.com/kubernetes/kubernetes/tree/master/api>
- <https://github.com/openshift/origin/tree/master/api>

## Web 应用程序目录

### `/web`

Web 应用程序特定组件:静态 Web 资产、服务器端模板和 SPAs。

## 通用应用程序目录

### `/configs`

配置文件模板，或默认配置文件。

把你的 `confd`或 `consul-template` 模板文件放在这里。

### `/init`

系统初始化(systemd, upstart, sysv)和进程管理器/supervisor (runit, supervisord)配置。

### `/scripts`

执行各种构建、安装、分析等操作的脚本。

这些脚本，可让根目录的 Makefile 文件保持小而简单(例如，`https://github.com/hashicorp/terraform/blob/master/Makefile`)

例子：

- <https://github.com/kubernetes/helm/tree/master/scripts>
- <https://github.com/cockroachdb/cockroach/tree/master/scripts>
- <https://github.com/hashicorp/terraform/tree/master/scripts>

### `/build`

打包与持续集成。

将云(AMI)、容器(Docker)、OS(deb、rpm、pkg)包配置和脚本放入 `/build/package` 目录。

把你的 CI(travis， circle， drone) 配置和脚本放在 `/build/ci` 目录。请注意，一些 CI 工具(例如，Travis CI)对配置文件的位置非常挑剔。在
尝试将配置文件放入 `/build/ci` 之后，请将它们链接到 CI 工具期望的位置(如果可能的话).

### `/deployments`

IaaS、PaaS、system 和 *容器编排部署* 配置和模板(docker-compose, kubernetes/helm, mesos, terraform, bosh)。

注意，在一些项目中（尤其是使用 kubernetes 部署的应用程序），这个目录被称为 `/deploy`。

### `/test`

额外的外部测试应用程序和测试数据。你可以随意构造 `/test`。或对于更大的项目来说，可以有一个数据子目录。例如，`/test/data` 或`/test/testdata`，
如果你需要 Go 忽略这个目录中的内容。注意，Go 还将忽略以 `.` or `_` 开头的目录或文件，因此在如何命名测试数据目录方面，具有更大的灵活性.

例子：

- <https://github.com/openshift/origin/tree/master/test> (test data is in the /testdata subdirectory)

## 其他目录

### `/docs`

程序设计和用户文档(除 godoc 生成的文档之外)。

见[`/docs`](docs/README.md)目录的例子。

### `/tools`

支撑该项目的工具。请注意，这些工具可以从 `/pkg` 和 `/internal` 目录导入和使用代码。

例子：

- <https://github.com/istio/istio/tree/master/tools>
- <https://github.com/openshift/origin/tree/master/tools>
- <https://github.com/dapr/dapr/tree/master/tools>

### `/examples`

应用程序，公共包的示例。

例子：

- <https://github.com/nats-io/nats.go/tree/master/examples>
- <https://github.com/docker-slim/docker-slim/tree/master/examples>
- <https://github.com/gohugoio/hugo/tree/master/examples>
- <https://github.com/hashicorp/packer/tree/master/examples>

### `/third_party`

外部辅助工具、被 fork 的代码和其他第三方实用程序(例如，Swagger UI)。

### `/githooks`

Git 钩子。

### `/assets`

与项目一起使用的其他资源(图像、logos 等)。

### `/website`

如果你没有使用 Github pages，这是放置项目网站的地方。

例子：

- <https://github.com/hashicorp/vault/tree/master/website>
- <https://github.com/perkeep/perkeep/tree/master/website>

## 你不应该拥有的目录

### `/src`

一些 GO 项目确实有 `src` 文件夹，但这种是在 Java 世界的开发中比较常见的模式。如果你不想让你的 Go 代码或 Go 项目看起来像 Java，就尽量不要使用
这种模式。

不要把项目级别的 `/src` 目录与 Go 的工作空间使用的 `/src` 目录混为一谈，如 [`How to Write Go Code`](https://golang.org/doc/code.html)
中的描述。

## 徽章

- [Go Report Card](https://goreportcard.com/)它会用 `gofmt`，`go vet`，`gocyclo`，`golint`，`ineffassign`，`license` 和
`misspell` 扫描你代码。将 `github.com/golang-standards/project-layout` 替换为你的项目。

- [GoDoc](http://godoc.org) 提供 GoDoc 生成文档的在线版本。请将链接更改为指向你项目的链接。

- [Release](https://shields.io/) 它将显示项目的最新发布号。更改 Github 链接指向你的项目。

[![Go Report Card](https://goreportcard.com/badge/github.com/golang-standards/project-layout?style=flat-square)](https://goreportcard.com/report/github.com/golang-standards/project-layout)
[![Go Doc](https://img.shields.io/badge/godoc-reference-blue.svg?style=flat-square)](http://godoc.org/github.com/golang-standards/project-layout)
[![Release](https://img.shields.io/github/release/golang-standards/project-layout.svg?style=flat-square)](https://github.com/golang-standards/project-layout/releases/latest)

## Note

一个更具自信心的项目模板，具有可重用的配置、脚本和代码。**WIP-工作正在进行中**。
