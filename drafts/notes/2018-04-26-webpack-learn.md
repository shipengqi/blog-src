---
title: Webpack 简单使用
date: 2018-04-26 17:51:28
categories: ["前端"]
tags: ["webpack"]
---

`webpack`是一个`Javascript`模块化的打包工具，扩展能力强大，但是学习起来不是很友好。



我刚开始使用`webpack`的时候，配置起来各种报错，搞的我怀疑人生。`webpack`已将到4.x了，
我以前的配置是基于3.x的，升级的时候又是各种报错，所以在此记录下来。

## 基本概念
`webpack`的四个核心概念：

- 入口(entry)
- 输出(output)
- loader
- 插件(plugins)

### 入口

在多个代码模块中会有一个起始的`.js`文件，这个便是 webpack 构建的入口。webpack 会读取这个文件，并从它开始解析依赖，然后进行打包。
通过在 webpack 配置中配置`entry`属性，来指定一个入口起点（或多个入口起点）。默认值为`./src`。
如果是单页面应用，那么可能入口只有一个；如果是多个页面的项目，那么经常是一个页面会对应一个构建入口。

```javascript
module.exports = {
  entry: './src/index.js'
}

// 上述配置等同于
module.exports = {
  entry: {
    main: './src/index.js'
  }
}

// 或者配置多个入口
module.exports = {
  entry: {
    foo: './src/page-foo.js',
    bar: './src/page-bar.js',
    // ...
  }
}

// 使用数组来对多个文件进行打包
module.exports = {
  entry: {
    main: [
      './src/foo.js',
      './src/bar.js'
    ]
  }
}
```

### 输出
指 webpack 打包完并输出的静态文件。使用`output`字段配置，例如：
```javascript
module.exports = {
  entry: './src/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'main.bundle.js'
  }
};
```

上面的代码中，`output.filename`指定输出文件的名称，`output.path`属性指定输出文件的路径。

```javascript
多个入口生成不同文件
module.exports = {
  entry: {
    foo: './src/foo.js',
    bar: './src/bar.js',
  },
  output: {
    filename: '[name].bundle.js',  //生成foo.bundle.js bar.bundle.js
    path: __dirname + '/dist',
  },
}

//使用 hash，每次构建时会有一个不同 hash 值，避免发布新版本时线上使用浏览器缓存
module.exports = {
  output: {
    filename: '[name].[hash].bundle.js',
    path: __dirname + '/dist',    //也可以在路径中使用hash, /dist/[hash]
  },
}
```

### loader

`loader`使`webpack`能够处理多种文件格式。`loader`可以理解为一个转换器，负责把某种文件格式的内容转换成 webpack 可以支持打包的模块。
例如，如果没有添加`loader`，webpack 会默认把所有依赖打包成`js`文件，如果入口文件依赖一个`.hbs`的模板文件，我们就需要添加`handlebars-loader`才可以处理`.hbs`文件
并解析成js代码，打包。

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

上面的代码中，`test`属性，用于匹配文件路径的正则表达式，通常都是匹配文件类型后缀。`use`属性，指定使用哪个`loader`。

### 插件
`loader` 用于处理转换某些类型的模块代码，而插件用于处理更多其他的构建任务。例如压缩js代码，通过配置`plugins`字段：
```javascript
const UglifyPlugin = require('uglifyjs-webpack-plugin')

module.exports = {
  plugins: [
    new UglifyPlugin()
  ],
}
```

### 模式
通过配置`development`或`production`设置`mode`参数，可以启用相应模式下的 webpack 内置的优化：
```javascript
module.exports = {
  mode: 'production'
};
```

## 3.x 与 4.x
webpack 4.x相比较 3.x 的主要变化：

- 4.x 拆分出了[webpack-cli](https://github.com/webpack/webpack-cli)
- 4.x 引入了零配置的概念
- 4.x 新增了`mode`参数(必要的参数)
- 4.x 删除了`CommonsChunkPlugin`，代码分离的功能在`optimization`配置
- 4.x 构建性能优化
- 4.x 默认支持[WebAssembly](https://developer.mozilla.org/en-US/docs/WebAssembly)

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


## 配置开发环境
基本前端开发环境需要：

- 构建 HTML、CSS、JS 文件
- 使用 CSS 预处理器来编写样式
- 处理和压缩图片
- 使用 Babel 来支持 ES 新特性
- 本地提供静态服务以方便开发调试

### HTML
通常生成的js文件时使用[hash]命名的，这个时候要讲HTML引用的js路径和我们通过webpack打包好的文件关联起来，就使用插件[html-webpack-plugin](https://github.com/jantimon/html-webpack-plugin)。
```javascript
const HtmlWebpackPlugin = require('html-webpack-plugin')

module.exports = {
  // ...
  plugins: [
    new HtmlWebpackPlugin({
      filename: 'index_production.html', // 输出文件名和路径
      template: 'assets/index.ejs', // 文件模板
      inject: false
    }),
  ],
}
```

模板`index.ejs`：
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>ChatOps</title>
    <link rel="stylesheet" href="<%= htmlWebpackPlugin.files.css[0] %>">
</head>
<body>
    <div id="app" class="container">

    </div>
    <script type="text/javascript" src="<%= htmlWebpackPlugin.files.js[0] %>"></script>
</body>
</html>
```

详细配置参考[官方文档](https://github.com/jantimon/html-webpack-plugin#configuration)。

### CSS

安装`css-loader`，`style-loader`后在配置中引入 loader 来解析和处理 CSS 文件：
```javascript
module.exports = {
  module: {
    rules: [
      // ...
      {
        test: /\.css/,
        include: [
          path.resolve(__dirname, 'src'),
        ],
        use: [
          'style-loader',
          'css-loader',
        ],
      },
    ],
  }
}
```

`css-loader`负责解析 CSS 代码，处理 CSS 中的依赖，例如`@import`和`url()`等引用外部文件的声明。
`style-loader`将`css-loader`解析的结果转变成`JS`代码，运行时动态插入`style`标签来让`CSS`代码生效。

#### 抽取CSS
使用[extract-text-webpack-plugin](https://webpack.docschina.org/plugins/extract-text-webpack-plugin)插件，可以把 CSS 文件分离出来：
```javascript
const ExtractTextPlugin = require('extract-text-webpack-plugin')

module.exports = {
  // ...
  module: {
    rules: [
      {
        test: /\.css$/,
        // 因为这个插件需要干涉模块转换的内容，所以需要使用它对应的 loader
        use: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          use: 'css-loader',
        }),
      },
    ],
  },
  plugins: [
    // 同样可以使用 [name] [hash]
    new ExtractTextPlugin({
      filename: '[name].[hash].bundle.css',
      allChunks: true
    }),
  ],
}
```

> `extract-text-webpack-plugin` 这个插件不支持 webpack 4.x，所以使用 4.x 时需要安装 alpha 版本:`npm install extract-text-webpack-plugin@next -save-dev`，3.x 请忽略。

#### CSS 预处理
通常我们会使用 Less/Sass 等 CSS 预处理器：
```javascript
module.exports = {
  // ...
  module: {
    rules: [
      {
        test: /\.less$/,
        use: ExtractTextPlugin.extract({
          fallback: 'style-loader',
          use: [
            'css-loader',
            'less-loader',
          ],
        }),
      },
    ],
  },
  // ...
}
```

### 处理图片
css-loader 会解析样式中用 url() 引用的文件路径，但是图片对应的 jpg/png/gif 等文件格式，webpack 处理不了，
所以我们使用 [file-loader](https://webpack.js.org/loaders/file-loader/) 来处理：
```javascript
module.exports = {
  // ...
  module: {
    rules: [
      {
        test: /\.(png|jpg|gif)$/,
        use: [
          {
            loader: 'file-loader',
            options: {},
          },
        ],
      },
    ],
  },
}
```

### Babel
```javascript
module.exports = {
  // ...
  module: {
    rules: [
      {
        test: /\.jsx?/,
        include: [
          path.resolve(__dirname, 'src'),
        ],
        loader: 'babel-loader',
      },
    ],
  },
}
```


### webpack-dev-server
安装webpack-dev-server：
```bash
npm install webpack-dev-server -D
```

添加npm脚本：
```javascript
"scripts": {
  "start:dev": "webpack-dev-server --mode development"
}
```