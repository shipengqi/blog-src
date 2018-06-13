---
title: Travis CI 教程
date: 2018-06-05 22:23:22
categories: ["Git"]
tags: ["Travis"]
---

Travis CI 提供的是持续集成服务（Continuous Integration，简称 CI）。它绑定 Github 上面的项目，只要有新的代码，就会自动抓取。然后，提供一个运行环境，执行测试，完成构建，还能部署到服务器。

<!-- more -->

## 开始使用

Travis CI 只支持 Github，不支持其他代码托管服务。

首先，访问[travis-ci 官方网站](https://travis-ci.org/)，使用 Github 账户登入 Travis CI。

Travis 会列出 Github 上面你的所有仓库，以及你所属于的组织。此时，选择你需要 Travis 帮你构建的仓库，打开仓库旁边的开关。一旦激活了一个仓库，Travis 会监听这个仓库的所有变化。
<img src="/images/travis/travis1.jpg" width="80%" height="">

## 配置.travis.yml

Travis 要求项目的根目录下面，必须有一个`.travis.yml`文件。这是配置文件，指定了 Travis 的行为。该文件必须保存在 Github 仓库里面，一旦代码仓库有新的 Commit，Travis 就会去找这个文件，执行里面的命令。

这个文件采用 `YAML` 格式。下面是一个最简单的 `python` 项目的`.travis.yml`文件。

```yml
language: python
script: true
```

上面代码中，设置了两个字段。`language`字段指定了默认运行环境，这里设定使用 `Python`环境。`script`字段指定要运行的脚本，`script: true`表示不执行任何脚本，状态直接设为成功。

Travis 默认提供的运行环境，请参考[官方文档](https://docs.travis-ci.com/user/languages)。目前一共支持31种语言，以后还会不断增加。

下面是一个稍微复杂一点的`.travis.yml`。

```yml
language: python
sudo: required
before_install: sudo pip install foo
script: py.test
```

上面代码中，设置了四个字段：运行环境是 `Python`，需要`sudo`权限，在安装依赖之前需要安装`foo`模块，然后执行脚本`py.test`。

## 运行流程
Travis 的运行流程很简单，任何项目都会经过两个阶段。
- install 阶段：安装依赖
- script 阶段：运行脚本

### install 字段

`install`字段用来指定安装脚本。
```yml
install: ./install-dependencies.sh
```
如果有多个脚本，可以写成下面的形式。
```yml
install:
  - command1
  - command2
```

上面代码中，如果command1失败了，整个构建就会停下来，不再往下进行。

如果不需要安装，即跳过安装阶段，就直接设为`true`。
```yml
install: true
```

### script 字段
`script`字段用来指定构建或测试脚本。
```yml
script: bundle exec thor build
```
如果有多个脚本，可以写成下面的形式。
```yml
script:
  - command1
  - command2
```
注意，`script`与`install`不一样，如果`command1`失败，`command2`会继续执行。但是，整个构建阶段的状态是失败。

如果`command2`只有在`command1`成功后才能执行，就要写成下面这样。
```yml
script: command1 && command2
```

### Node 项目
Node 项目的环境需要写成下面这样。
```yml
language: node_js
node_js:
  - "8"
```
`node_js`字段用来指定 Node 版本。

Node 项目的`install`和`script`阶段都有默认脚本，可以省略。
- `install`默认值：npm install
- `script`默认值：npm test

更多设置请看[官方文档](https://docs.travis-ci.com/user/languages/javascript-with-nodejs/)。

### 部署
`script`阶段结束以后，还可以设置[通知步骤](https://docs.travis-ci.com/user/notifications/)（notification）和[部署步骤](https://docs.travis-ci.com/user/deployment/)（deployment），它们不是必须的。

部署的脚本可以在`script`阶段执行，也可以使用 Travis 为几十种常见服务提供的快捷部署功能。比如，要部署到 Github Pages，可以写成下面这样。
```yml
deploy:
  provider: pages
  skip_cleanup: true
  github_token: $GITHUB_TOKEN # Set in travis-ci.org dashboard
  on:
    branch: master
```

其他部署方式，请看[官方文档](https://docs.travis-ci.com/user/deployment/)。

### 钩子方法
Travis 为上面这些阶段提供了7个钩子。

- before_install：install 阶段之前执行
- before_script：script 阶段之前执行
- after_failure：script 阶段失败时执行
- after_success：script 阶段成功时执行
- before_deploy：deploy 步骤之前执行
- after_deploy：deploy 步骤之后执行
- after_script：script 阶段之后执行

完整的生命周期，从开始到结束是下面的流程。
1. before_install
2. install
3. before_script
4. script
5. aftersuccess or afterfailure
6. [OPTIONAL] before_deploy
7. [OPTIONAL] deploy
8. [OPTIONAL] after_deploy
9. after_script

下面是一个before_install钩子的例子。
```yml
before_install:
  - sudo apt-get -qq update
  - sudo apt-get install -y libxml2-dev
```
上面代码表示`before_install`阶段要做两件事，第一件事是要更新依赖，第二件事是安装`libxml2-dev`。
用到的几个参数的含义如下：`-qq`表示减少中间步骤的输出，`-y`表示如果需要用户输入，总是输入`yes`。

### 运行状态
最后，Travis 每次运行，可能会返回四种状态。

- passed：运行成功，所有步骤的退出码都是0
- canceled：用户取消执行
- errored：before_install、install、before_script有非零退出码，运行会立即停止
- failed ：script有非零状态码 ，会继续运行

## 使用技巧

### 环境变量
`.travis.yml`的`env`字段可以定义环境变量。
```yml
env:
  - DB=postgres
  - SH=bash
  - PACKAGE_VERSION="1.0.*"
```
然后，脚本内部就使用这些变量了。

有些环境变量（比如用户名和密码）不能公开，这时可以通过 Travis 网站，写在每个仓库的设置页里面，Travis 会自动把它们加入环境变量。
这样一来，脚本内部依然可以使用这些环境变量，但是只有管理员才能看到变量的值。具体操作请看[官方文档](https://docs.travis-ci.com/user/environment-variables)。
<img src="/images/travis/travis2.png" width="80%" height="">
### 加密
如果不放心保密信息明文存在 Travis 的网站，可以使用 Travis 提供的加密功能。[官方文档](https://docs.travis-ci.com/user/encryption-keys/)
如果要加密的是文件（比如私钥），Travis 提供了加密文件功能。[官方文档](https://docs.travis-ci.com/user/encrypting-files/)
实际的例子可以参考下面两篇文章。
- [Auto-deploying built products to gh-pages with Travis](https://gist.github.com/domenic/ec8b0fc8ab45f39403dd)
- [SSH deploys with Travis CI](https://oncletom.io/2016/travis-ssh-deploy/)


## 添加图标

### 添加`build`状态图标
我们可以在项目中添加 Travis CI build的状态图标，点击下图中的图标获取连接：
<img src="/images/travis/travis3.jpg" width="80%" height="">

### coverage 图标

[Codecov](https://codecov.io/gh)是一个测试结果分析工具，travis负责执行测试，Codecov负责分析测试结果。很多项目通过他测试覆盖率。


#### 使用

去[官网](https://codecov.io/)，使用 Github 账户登入。选择要分析的仓库。

修改`.travis.yml`文件：
```yml
before_install:
  - npm install codecov
  - npm install coverage

script:
  - coverage command
after_script:
  - codecov
```

添加下面格式的链接到`Readme`。
```
[![codecov](https://codecov.io/gh/{USER}/{REPO}/branch/master/graph/badge.svg)](https://codecov.io/gh/{USER}/{REPO})
```

更多配置参考[官方文档](https://docs.codecov.io/docs)。

更多图标可以在[这里](http://shields.io)找。


**原文出自** [持续集成服务 Travis CI 教程](http://www.ruanyifeng.com/blog/2017/12/travis_ci_tutorial.html)