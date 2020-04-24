---
title: 使用 lerna 管理 npm packages
date: 2019-10-31 14:55:55
categories: ["Node.js"]
---


[lerna](https://github.com/lerna/lerna) 是一个基于 git 和 npm 的多包管理工具。


<!-- more -->

## 为什么需要 lerna？
1. 解决多个 packages 之间的依赖关系。

比如，现在有两个 packages，分别是 `package-1` 和 `package-2`。
`package-1` 的 `package.json` 文件：
```json
{
  "name": "package-1",
  "version": "1.0.0",
  "scripts": {
    "start": "hexo s -p 8081"
  },
  "dependencies": {
    "package-2": "1.0.0"
  }
}
```

`package-2` 的 `package.json` 文件：
```json
{
  "name": "package-2",
  "version": "1.0.0",
  "dependencies": {}
}
```

可以看出 `package-2` 是 `package-1` 的依赖包。如果 `package-2` 要 publish `1.0.1`。那么 `package-1` 也要修改依赖的 `package-2` 的
版本，并且 publish。

如果互相依赖的 package 很多，工作量就会变得很大。

2. 通过 git 检测文件改动，自动发布。
2. 根据 git 提交记录，自动生成 `CHANGELOG`。

## 使用

### 全局安装 lerna
```sh
npm install lerna -g
```

### 初始化一个 lerna 工程

```sh
# 创建 lerna 工程目录 lerna-demo
mkdir lerna-demo
cd lerna-demo

# 初始化
lerna init

# 在 packages 目录下添加 package
cd packages
mkdir package-1 package-2

# 初始化 package
cd package-1
npm init -y

cd package-2
npm init -y
```

最后，项目结构像下面这样：

```sh
lerna-demo/
  package.json
  lerna.json # 配置文件
  packages/  # package 目录
    package-1/
      package.json
    package-2/
      package.json
```

安装 packages 依赖：
```sh
# 在 lerna 根目录（lerna-demo）下执行
lerna bootstrap
```

`lerna bootstrap` 会安装 packages 下所有 packages 的依赖。

## 两种工作模式
### Fixed/Locked mode
Fixed/Locked mode 是默认的模式。这种模式下，packages 下的所有包共用一个版本号 (version)，会自动将所有的包绑定到一个版本号上(该版本号
就是 `lerna.json` 中的 `version` 字段)，所以任意一个包发生了更新，这个共用的版本号就会发生改变。这种模式下，每次发布 packages，都是全量
发布，无论是否修改。

### Independent mode
在 Independent mode 下，lerna 会配合 Git，检查文件变动，只发布有改动的 packages。如果要使用 Independent mode，使用 
`lerna init --independent` 来初始化项目。

Independent mode 允许每一个包有一个独立的版本号，在使用 `lerna publish` 命令时，可以为每个包制定具体的操作，同时可以只更新某一个包的版本号。


更多 lerna 使用可以查看 [官方文档](https://lerna.js.org/) 。