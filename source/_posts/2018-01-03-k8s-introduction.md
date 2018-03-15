---
title: Kubernetes简介
date: 2018-01-03 10:28:09
categories: ["Linux"]
tags: ["Kubernetes"]
---

Kubernetes是谷歌开源的容器集群管理系统，是Google多年大规模容器管理技术Borg的开源版本，主要功能包括：

- 基于容器的应用部署、维护和滚动升级
- 负载均衡和服务发现
- 跨机器和跨地区的集群调度
- 自动伸缩
- 无状态服务和有状态服务
- 广泛的Volume支持
- 插件机制保证扩展性

Kubernetes发展非常迅速，已经成为容器编排领域的领导者。

<!-- more -->

## Kubernetes是一个平台

Kubernetes 提供了很多的功能，它可以简化应用程序的工作流，加快开发速度。通常，一个成功的应用编排系统需要有较强的自动化能力，这也是为什么 Kubernetes 被设计作为构建组件和工具的生态系统平台，以便更轻松地部署、扩展和管理应用程序。

用户可以使用Label以自己的方式组织管理资源，还可以使用Annotation来自定义资源的描述信息，比如为管理工具提供状态检查等。

此外，Kubernetes控制器也是构建在跟开发人员和用户使用的相同的API之上。用户还可以编写自己的控制器和调度器，也可以通过各种插件机制扩展系统的功能。

这种设计使得可以方便地在Kubernetes之上构建各种应用系统。

## Kubernetes不是什么

Kubernetes 不是一个传统意义上，包罗万象的 PaaS (平台即服务) 系统。它给用户预留了选择的自由。

- 不限制支持的应用程序类型，它不插手应用程序框架, 也不限制支持的语言 (如Java, Python, Ruby等)，只要应用符合 [12因素](http://12factor.net/) 即可。Kubernetes 旨在支持极其多样化的工作负载，包括无状态、有状态和数据处理工作负载。只要应用可以在容器中运行，那么它就可以很好的在 Kubernetes 上运行。
- 不提供内置的中间件 (如消息中间件)、数据处理框架 (如Spark)、数据库 (如 mysql)或集群存储系统 (如Ceph)等。这些应用直接运行在 Kubernetes之上。
- 不提供点击即部署的服务市场。
- 不直接部署代码，也不会构建您的应用程序，但您可以在Kubernetes之上构建需要的持续集成 (CI) 工作流。
- 允许用户选择自己的日志、监控和告警系统。
- 不提供应用程序配置语言或系统 (如 [jsonnet](https://github.com/google/jsonnet))。
- 不提供机器配置、维护、管理或自愈系统。

另外，已经有很多 PaaS 系统运行在 Kubernetes 之上，如 [Openshift](https://github.com/openshift/origin), [Deis](http://deis.io/) 和 [Eldarion](http://eldarion.cloud/) 等。 您也可以构建自己的PaaS系统，或者只使用Kubernetes管理您的容器应用。

当然了，Kuberenets不仅仅是一个“编排系统”，它消除了编排的需要。Kubernetes通过声明式的API和一系列独立、可组合的控制器保证了应用总是在期望的状态，而用户并不需要关心中间状态是如何转换的。这使得整个系统更容易使用，而且更强大、更可靠、更具弹性和可扩展性。

## 主要组件

Kubernetes主要由以下几个核心组件组成：

- etcd保存了整个集群的状态；
- apiserver提供了资源操作的唯一入口，并提供认证、授权、访问控制、API注册和发现等机制；
- controller manager负责维护集群的状态，比如故障检测、自动扩展、滚动更新等；
- scheduler负责资源的调度，按照预定的调度策略将Pod调度到相应的机器上；
- kubelet负责维护容器的生命周期，同时也负责Volume（CVI）和网络（CNI）的管理；
- Container runtime负责镜像管理以及Pod和容器的真正运行（CRI）；
- kube-proxy负责为Service提供cluster内部的服务发现和负载均衡

![](/images/k8s/architecture.png)



## 社区采纳情况

![](/images/k8s/infographic_ExcitedAboutKubernetes_Sep.png)

(图片来自[Apprenda](https://apprenda.com/blog/customers-really-using-kubernetes/))

## 参考文档

- [What is Kubernetes?](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [HOW CUSTOMERS ARE REALLY USING KUBERNETES](https://apprenda.com/blog/customers-really-using-kubernetes/)

**本文出自：** [Kubernetes指南](https://www.gitbook.com/book/feisky/kubernetes/details)