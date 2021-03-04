---
title: Webpack 不同环境的配置
date: 2018-06-22 14:40:22
categories: ["前端"]
tags: ["webpack"]
---

在日常的开发中，我们可能有多套环境，用于构建的环境，用于开发的环境，用于测试的环境等。针对不同的环境，我们需要不同的配置。



比如，开发环境下，我们需要调试，因此不需要压缩js文件，需要打印 debug 信息，包含 sourcemap 文件；
生产环境下，代码应该都是压缩后的，不打印 debug 信息，静态文件不包括 sourcemap 的。测试环境的话，需要 mock 请求，或者配置 mock server。

## mode
webpack 4.x 版本引入了`mode`的概念，在运行`webpack`时指定`production`或 `evelopment`
当使用`production`时，默认会启用各种性能优化的功能，包括构建结果优化以及 webpack 运行性能优化，使用 JS 代码压缩。
如果是`development`的，则会开启 debug 工具，运行时打印详细的错误信息，以及更加快速的增量编译构建。

## 在配置文件中区分 mode
webpack 的`mode`参数，在某些场景下，可能还不满足我们的需求，比如，不同环境下加载不同的loader，plugin。所以，我们需要在配置文件中区分`mode`。

在webpack 3.x 中常用的做法是想下面的命令：
```bash
cross-env NODE_ENV=production webpack --config build/webpack.client.config.js --progress --hide-modules
```

运行webpack 是配置`NODE_ENV=production`，在配置文件中，通过`process.env.NODE_ENV`来获取`mode`。

在webpack 4.x 中，我们可以通过下面的方式获取`mode`：
```javascript
// webpack.client.config.js
module.exports = (env, argv) => ({
  // ... 其他配置
  optimization: {
    minimize: false,
    // 使用 argv 来获取 mode 参数的值
    minimizer: argv.mode === 'production' ? [
      new UglifyJsPlugin({ /* 你自己的配置 */ }),
      // 仅在我们要自定义压缩配置时才需要这么做
      // mode 为 production 时 webpack 会默认使用压缩 JS 的 plugin
    ] : [],
  },
})
```
我们还可以通过[DefinePlugin](https://doc.webpack-china.org/plugins/define-plugin)插件，在构建时给运行时定义变量。

## 不同环境的差异配置

- 生产环境：分离 CSS 成单独的文件，以便多个页面共享同一个 CSS 文件
- 生产环境：压缩 HTML/CSS/JS 代码
- 生产环境：压缩图片
- 开发环境： sourcemap 文件
- 开发环境：打印 debug 信息
- 开发环境： live reload 或者 hot reload 的功能

在不同的环境下，一般我们会拆分出不同的文件,比如：

- webpack.base.config.js
- webpack.development.config.js
- webpack.production.config.js
- webpack.test.config.js
- webpack.client.config.js //SSR
- webpack.server.config.js //SSR

webpack 的配置，其实是对外暴露一个 JS 对象，因此我们是可以像修改js代码一样修改它。我们可以使用[webpack-merge](https://github.com/survivejs/webpack-merge)，
把不同的配置merge到一起，比如上面的`webpack.base.config.js`，就是基础配置文件，其他的文件都可以使用 webpack-merge，把基础配置merge 进来。

## 开发环境下配置 HMR
HMR 全称是 Hot Module Replacement，即模块热替换，就是热加载。
```javascript
module.exports = {
  // ...
  devServer: {
    hot: true // dev server 的配置要启动 hot，或者在命令行中带参数开启
  },
  plugins: [
    // ...
    new webpack.NamedModulesPlugin(), // 用于启动 HMR 时可以显示模块的相对路径
    new webpack.HotModuleReplacementPlugin(), // Hot Module Replacement 的插件
  ],
}
```
