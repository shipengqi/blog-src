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

### test
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

### 其他匹配条件
一般配置 loader 的匹配条件时，配置`test`字段就足够了，但是有时需要一些特殊的配置，webpack 提供了多种匹配条件：

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

### use
上面的例子中提到，使用`use`字段指定使用哪个`loader`,`use`的值除了可以是字符串，还可以是数组，或者对象：
```javascript
rules: [
  {
    test: /\.less/,
    use: [
      'style-loader', // 使用字符串指定 loader
      {
        loader: 'css-loader',
        options: {
          importLoaders: 1
        }
      } // 使用对象指定 loader，可以传递 loader 配置等
    ],
  }
],
```
如果只需要一个`loader`，也可以这样：`use: { loader: 'babel-loader', options: { ... } }`。

### loader 执行顺序

两种情况：

**在一个`rule`中配置了多个`loader`，那么执行顺序从是最后配置的`loader`开始。**

```javascript
rules: [
  {
    test: /\.less/,
    use: [
      'style-loader',
      {
        loader: 'css-loader',
        options: {
          importLoaders: 1
        }
      },
      {
        loader: 'less-loader',
        options: {
          noIeCompat: true
        }
      },
    ],
  }
]
```

上面的示例,一个`style.less`文件会经过 `less-loader` => `css-loader` => `style-loader` 处理，然后打包。

**在不同的`rule`，匹配了同种类型的文件：**
```javascript
rules: [
  {
    enforce: 'pre',
    test: /\.(jsx|js)$/,
    exclude: /node_modules/,
    loader: "eslint-loader",
  },
  {
    test: /\.(jsx|js)$/,
    exclude: /node_modules/,
    loader: "babel-loader",
  },
]
```

上面的示例中，多了一个`enforce`字段，这个字段作用就是保证`loader`的执行顺序。`pre`代表了前置，保证了`eslint-loader`在`babel-loader`前执行。

`enforce`字段有下面两种类型：

- `pre`，表示前置类型的`loader`
- `post`，表示后置类型的`loader`

没有`enforce`字段，就是普通类型。
这些`loader`的执行顺序为 `前置` => `普通` => `后置`

### noParse
`noParse` 让 webpack 忽略对某些模块文件的解析。可以用来优化 webpack 的构建速度。
`noParse`类型可以是正则表达式，也可以一个函数。
```javascript
module.exports = {
  // ...
  module: {
    noParse: /jquery|lodash/, // 正则表达式

    // 使用 function
    noParse(content) {
      return /jquery|lodash/.test(content)
    },
  }
}
```

**被忽略的模块中，不应该有`import`，`define`，`require`等模块化语句，包含这些语句的模块需要 webpack 解析，否则无法再浏览器端运行。**

## 配置 plugin
插件是 webpack 的支柱功能。插件解决了`loader`无法实现的事情。

### 常用的插件

#### DefinePlugin
`DefinePlugin` 是内置的插件，使用`webpack.DefinePlugin`直接获取。
`DefinePlugin`用于创建一些在编译时可以配置的全局变量。

```javascript
module.exports = {
  // ...
  plugins: [
    new webpack.DefinePlugin({
      ENV: 'production',
      TEST: '1+1',
      CONSTANTS: {
        VERSION: JSON.stringify('1.0.0')
      }
    }),
  ],
}
```

配置好之后，可以在代码中直接访问：
```javascript
console.log("ENV: ", ENV);
```
**配置规则：**

- 如果配置的值是字符串，那么字符串会被当成代码片段来执行，其结果作为最终变量的值，如上面的`TEST: "1+1"`，最后的结果是 2
- 如果不是字符串，也不是一个对象字面量，那么该值会被转为一个字符串，如 `true`，最后的结果是 `'true'`
- 如果一个对象字面量，那么该对象的所有`key`会以同样的方式去定义

#### ProvidePlugin
内置的插件，使用`webpack.ProvidePlugin`来获取。
用于引用某些模块作为应用运行时的变量，从而不需要每次使用`require`或者`import`去引用：
```javascript
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      "window.jQuery": "jquery",
      identifier: 'module',
    })
  ]
```

上面的示例，将`$`和`jQuery`两个变量都指向对应的`jquery`模块，然后在源码中可以使用下面的方式调用：
```javascript
$('#test');
jQuery('#test');
```
上面的情况在使用`bootstrap`时就需要配置，否则后报错`jQuery is not a function`。
`Angular`会寻找`window.jQuery`来决定`jQuery`是否存在。

上面的示例，当 identifier 被当作未赋值的变量时，module 就会被自动加载，而 `identifier` 这个变量即 `module` 对外暴露的内容。
注意，如果是`ES6`的`default export`，那么需要指定模块的`default`属性：`identifier: ['module', 'default']`。.

#### IgnorePlugin
内置的插件，使用`webpack.IgnorePlugin`来获取。
用于忽略某些特定的模块，让 webpack 不把这些指定的模块打包进去。
例如`moment.js`，里边有大量的`i18n`的代码，这下`locale`会导致打包出来的文件较大，实际上我们并不需要这些`i18n`的代码，这时可以使用`IgnorePlugin`来忽略掉这些代码文件：
```javascript
module.exports = {
  // ...
  plugins: [
    new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
  ]
}
```
`IgnorePlugin`的第一个参数是匹配引入模块路径的正则表达式，第二个是匹配模块的对应上下文，即所在目录名。

#### extract-text-webpack-plugin
用来把依赖的`CSS`分离出来成为单独的文件。

```javascript
module: {
  rules: [
    {
      test: /\.css$/,
      use: ExtractTextPlugin.extract({
        use: 'css-loader',
        fallback: 'style-loader'
      })
    }
  ]
},
plugins: [
  new ExtractTextPlugin({
    filename: '[name].css',
    allChunks: true
  })
]
```

**更多插件**[plugins in awesome-webpack](https://github.com/webpack-contrib/awesome-webpack#webpack-plugins)

## webpack-dev-server
`webpack-dev-server`可以快速的启动一个开发环境，支持热重载。
`webpack-dev-server`[官方文档](https://webpack.docschina.org/configuration/dev-server/)。

### 安装
```bash
//全局
npm install webpack-dev-server -g


//安装到项目中
npm install webpack-dev-server --save-dev
```

### 使用
`webpack-dev-server`本质上也是调用 webpack ，在`4.x`需要指定`mode`，添加`npm`脚本：
```javascript
"scripts": {
  "start:dev": "webpack-dev-server --mode development"
}
```

`webpack-dev-server`默认端口是`8080`，运行`npm run start:dev`，就可以访问`http://localhost:8080/`了。如果使用了`html-webpack-plugin`来构建`HTML`文件，
并且有一个`index.html`的构建结果，就可以看到`index.html`页面，如果没有`HTML`文件的话，会生成一个展示静态资源列表的页面。

index.html：
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>ChatOps Configuration</title>
    <link rel="stylesheet" type="text/css" href="/dist/app.css">
</head>
<body>
    <div id="app" class="container">

    </div>
    <script type="text/javascript" src="/dist/app.js"></script>
</body>
</html>
```


### 配置
可以在 webpack 的配置文件中通过`devServer`字段来配置`webpack-dev-server`：
```javascript
devServer: {
  contentBase: path.join(__dirname, "dist"),
  compress: true,
  port: 9000
}
```

上面的示例，所有来自`dist/`目录的文件都做`gzip`压缩，dev server 的端口为`9000`。

#### 常用配置选项

- `public`字段用于指定静态服务的域名，默认是`localhost:8080` ，当使用`Nginx`来做反向代理时，就需要使用该配置来指定`Nginx`配置使用的服务域名。
- `port`指定端口，默认是 8080。
- `publicPath`指定构建好的静态文件在浏览器中用什么路径去访问，默认是`/`，例如，对于一个构建好的文件`bundle.js`，完整的访问路径是`http://localhost:8080/bundle.js`，
如果配置了`publicPath: 'assets/'`，那么`bundle.js`的完整访问路径就是`http://localhost:8080/assets/bundle.js`。也可以使用整个`URL`来作为`publicPath`的值，
如`publicPath: 'http://localhost:8080/assets/'`。**如果使用了`HMR`，那么要设置`publicPath`就必须使用完整的`URL`。**
**`devServer.publicPath` 和 `output.publicPath`的值最好保持一致。**
- `proxy`，代理，给特定`URL`的配置代理。例如：
```javascript
proxy: {
  '/api': {
    target: "http://localhost:8081", // url 中带有 /api 的请求代理到 localhost:8081 端口的服务上
    pathRewrite: { '^/api': '' }, // 把 URL 中 path 部分的 api 移除掉
  },
}
```
  `proxy`功能基于`http-proxy-middleware`实现，`http-proxy-middleware`[官方文档](https://github.com/chimurai/http-proxy-middleware)。

- `contentBase` 配置提供额外静态文件内容的目录，之前提到的`publicPath`是配置构建好的结果以什么样的路径去访问，而`contentBase`是配置额外的静态文件内容的访问路径，
即那些不经过 webpack 构建，但是需要在`webpack-dev-server`中提供访问的静态资源（如部分图片等）。使用绝对路径：
```javascript
// 使用当前目录下的 public
contentBase: path.join(__dirname, "public")

// 也可以使用数组提供多个路径
contentBase: [path.join(__dirname, "public"), path.join(__dirname, "assets")]
```
  **`publicPath`的优先级高于`contentBase`。**
- `before`在`webpack-dev-server`静态资源中间件处理之前，可以用于拦截部分请求返回特定内容，或者实现简单的数据`mock`。
```javascript
before(app){
  app.get('/some/path', function(req, res) { // 当访问 /some/path 路径时，返回自定义的 json 数据
    res.json({ custom: 'response' })
  })
}
```
- `after`在`webpack-dev-server`静态资源中间件处理之后，比较少用到，可以用于打印日志或者做一些额外处理。

#### webpack-dev-middleware
`webpack-dev-middleware`是一个`Express`中间件，可以把`webpack-dev-server`和`Express`集成。
使用`webpack-dev-middleware`可以`mock`数据，方便开发。还可以实现代理API。

##### 安装webpack-dev-middleware
```bash
npm install webpack-dev-middleware --save-dev
```

##### 与`Express`集成
```javascript
const webpack = require('webpack')
const middleware = require('webpack-dev-middleware')
const webpackOptions = require('./build/webpack.base.config.js')

// 开发环境
webpackOptions.mode = 'development'

const compiler = webpack(webpackOptions)
const express = require('express')
const app = express()

app.use(middleware(compiler, {
  // webpack-dev-middleware 的配置
}))

// app.use(...)

app.listen(8080, () => {
  console.log('Start server on port 8080.')
})
```

然后运行:
```bash
node app.js
```
