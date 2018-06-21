---
title: Webpack 配置
date: 2018-06-21 15:05:23
categories: ["前端"]
tags: ["webpack"]
---

记录 webpack 常用的配置。

<!-- more -->

## 解析路径
webpack 依赖 [enhanced-resolve](https://github.com/webpack/enhanced-resolve/) 来解析代码模块的路径
### alias

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

### extensions
### modules
### mainFields
### mainFiles
### resolveLoader