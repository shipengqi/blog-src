---
title: Webpack 配置
date: 2018-06-21 15:05:23
categories: ["前端"]
tags: ["webpack"]
---

记录 webpack 常用的配置。

<!-- more -->

## 解析路径
webpack 依赖 [enhanced-resolve](https://github.com/webpack/enhanced-resolve/) 来解析代码模块的路径。
在 webpack 配置中，和模块路径解析相关的配置都在 `resolve` 字段下：
```javascript
module.exports = {
  resolve: {
    alias: {
      utils: path.resolve(__dirname, 'lib/utils')
    }
  }
}
```
### resolve.alias

当我们有某个模块，引用比较多，例如`import './lib/utils/helper.js'`，这种引用比较麻烦，我们可以通过配置别名来应用：
```javascript
alias: {
  utils: path.resolve(__dirname, 'lib/utils')
}
```

这种配置是模糊匹配，模块路径中携带了`utils`就可以，然后就可以直接引用：
```javascript
import 'utils/helper.js'
```

如果需要进行精确匹配可以使用：
```javascript
alias: {
  utils$: path.resolve(__dirname, 'lib/utils') // 只会匹配 import 'utils'
}
```

Resolve Alias[官方文档](https://webpack.docschina.org/configuration/resolve/#resolve-alias)。

### resolve.extensions
```javascript
resolve: {
  extensions: [".wasm", ".mjs", ".js", ".json", ".jsx"],
},
```
上面的示例中，数组`extensions`里的顺序代表匹配后缀的优先级，例如，`src`目录下有`index.jsx`，`index.js`：
```javascript
import App from './src/index'
```
会优先匹配`index.js`。`extensions`数组中没有的后缀，则不会匹配。

### resolve.modules

对于通过`npm`安装的第三方模块，`webpack`的加载机制与nodejs类似，它会搜索`node_modules`目录，这个目录可以使用`resolve.modules`字段进行配置的，默认是：
```javascript
resolve: {
  modules: ['node_modules'],
},
```
通常不需要改变这个配置，但是如果确定项目内所有的第三方依赖模块都是在项目根目录下的`node_modules`中，那么可以在`node_modules`之前配置一个确定的绝对路径：
```javascript
resolve: {
  modules: [
    path.resolve(__dirname, 'node_modules'), // 指定 node_modules 目录
    'node_modules', // 可以添加自定义的路径或者目录
  ],
},
```
这样配置可以简化模块的查找，提升构建速度。

### resolve.mainFiles

当目录下没有 package.json 文件时，会默认使用目录下的`index.js`，可以使用`resolve.mainFiles`字段，默认配置是：
```javascript
resolve: {
  mainFiles: ['index'],
},
```
通常情况下无须修改这个配置。


## loader 配置
loader 用于处理不同的文件类型。

### 匹配规则
通过`module.rules` 字段来配置相关的规则：
```javascript
module: {
  // ...
  rules: [
    {
      test: /\.jsx?/,
      include: [
        path.resolve(__dirname, 'lib') // 指定需要经过 loader 处理的文件路径
      ],
      use: 'babel-loader',
    },
  ],
}
```
两个最关键的因素: 匹配条件, 使用的 loader

- `test`属性，用于匹配文件路径的正则表达式，通常都是匹配文件类型后缀。include 也属于条件
- `use`属性，指定使用哪个`loader`。

匹配条件通常都使用请求资源文件的绝对路径来进行匹配，在官方文档中称为`resource`。
上面的代码中的 `test` 和 `include` 是 `resource.test` 和 `resource.include` 的简写，你也可以这么配置：

```javascript
module.exports = {
  rules: [
      {
        resource: {
          test: /\.jsx?/,
          include: [
            path.resolve(__dirname, 'src'),
          ],
        },
        use: 'babel-loader',
      },
      // ...
    ],
}
```

### 规则条件
一般配置 loader 的匹配条件时，配置`test`字段就足够了，但是有时需要一些特殊的配置，webpack 提供了多种配置形式：

- `{ test: ... }` 匹配特定条件
- `{ include: ... }` 匹配特定路径
- `{ exclude: ... }` 排除特定路径
- `{ and: [...] }` 必须匹配数组中所有条件
- `{ or: [...] }` 匹配数组中任意一个条件
- `{ not: [...] }` 排除匹配数组中所有条件

匹配条件的值可以是，字符串，正则表达式，函数( `(path) => boolean`，返回 `true` 表示匹配 )，数组，对象。

```javascript
module: {
  // ...
  rules: [
    {
      test: /\.jsx?/,
      include: [
        path.resolve(__dirname, 'lib') // 指定需要经过 loader 处理的文件路径
      ],
      not: [
        (value) => { /* ... */ return true; },
      ]
      use: 'babel-loader',
    },
  ],
}
```
