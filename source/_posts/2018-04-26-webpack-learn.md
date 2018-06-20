---
title: Webpack 使用
date: 2018-04-26 17:51:28
categories: ["前端"]
tags: ["webpack"]
---

`webpack`是一个`Javascript`模块化的打包工具，扩展能力强大，但是学习起来不是很友好。

<!-- more -->

我刚开始使用`webpack`的时候，配置起来各种报错，搞的我怀疑人生。`webpack`已将到4.x了，
我以前的配置是基于3.x的，升级的时候又是各种报错，所以在此记录下来。

## 基本概念
`webpack`的四个核心概念：

- 入口(entry)
- 输出(output)
- loader
- 插件(plugins)

## 安装
[webpack-cli](https://github.com/webpack/webpack-cli) 4.x 版本之后与`webpack`分离了，需要单独安装。

```bash
#全局安装
npm install webpack webpack-cli -g

webpack --help

#通常会把webpack安装到项目中
npm install webpack webpack-cli --save-dev
```

## 简单使用
4.x 的版本不需要配置就进行构建，但是功能不全面，不建议使用。

加一个 npm scripts：
```javascript
"scripts": {
  "build": "webpack --mode production"
}
```

创建一个`./src/index.js`文件，执行`npm run build`，`webpack`会生成一个`dist`目录，里边就是构建好的`main.js`文件。