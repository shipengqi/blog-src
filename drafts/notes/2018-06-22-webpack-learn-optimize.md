---
title: Webpack 优化
date: 2018-06-22 14:33:20
categories: ["前端"]
tags: ["webpack"]
---

使用 webpack 有一段时间了，但是在构建的时候慢的一批，所以就要学习一下，webpack 如何优化。



优化分为两部分，webpack 的构建速度和浏览器的加载速度，这里先学习提升 webpack 的构建速度。
提升 webpack 构建速度其实就是想办法让 webpack 少干点活，避免 webpack 去做一些不必要的事情。

## 配置resolve

我们知道`resolve`可以配置模块路径规则，让 webpack 在查询模块路径时快速地定位到模块，避免额外的查询：
```javascript
resolve: {
  modules: [
    path.resolve(__dirname, 'node_modules'), // 使用绝对路径指定 node_modules
  ],

  // 删除不必要的后缀自动补全
  extensions: [".js"],

  // 避免新增默认文件
  mainFiles: ['index'],
}
```

编码时，尽可能编写完整的路径，如：`import './lib/slider/index.js'`。


##  指定loader 应用的范围

指定loader处理文件的目录，避免处理不必要的文件：
```javascript
rules: [
  {
    test: /\.jsx?/,
    include: [
      // 一般代码会放在 src 目录，只有 src 目录下的 js/jsx 文件需要 babel-loader 处理
      path.resolve(__dirname, 'src')
    ],
    use: 'babel-loader'
  }
]
```

##  移除不必要的plugin

比如 mode 是 development 时，避免使用 UglifyJsPlugin，ExtractTextPlugin，提高加载速度。
