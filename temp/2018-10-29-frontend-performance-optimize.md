---
title: 前端性能优化
date: 2018-10-29 10:58:53
categories: ["前端"]
---

前端性能优化

<!-- more -->

## 从输入 URL 到页面加载完成
从输入 URL 到页面加载完成，发生了什么？

1. DNS 解析
2. TCP 连接
3. HTTP 请求/响应
4. 服务端处理请求，HTTP 响应返回
5. 浏览器拿到响应数据，解析响应内容，把解析的结果展示给用户

了解了整个过程，我们再来看如何优化。

网络层面的性能优化：

DNS 解析花时间，通过浏览器 DNS 缓存和 DNS prefetch尽量减少解析次数或者把解析前置。TCP 每次的三次握手慢，可以使用长连接、预连接、接入 SPDY 协议。
这两个过程的优化往往需要我们和团队的服务端工程师协作完成，那么前端单方面可以做那些优化？
答案是 HTTP 请求，减少请求次数和减小请求体积。服务器越远，一次请求就越慢，那部署时就把静态资源放在离我们更近的 CDN 上是不是就能更快一些？

浏览器端的性能优化：
资源加载优化、服务端渲染、浏览器缓存机制的利用、DOM 树的构建、网页排版和渲染过程、回流与重绘的考量、DOM 操作的合理规避等等。

## 网络层面
网络层面包含下面三个过程：
1. DNS 解析
2. TCP 连接
3. HTTP 请求/响应

我们能做优化的是 HTTP 优化：
- 减少请求次数
- 减少单次请求所花费的时间

如何优化？**就是常见的资源的压缩与合并**。我们常用的构建工具应该是 webpack。

### webpack 优化
webpack 的优化瓶颈，主要是两个方面：

- webpack 的构建过程太花时间
- webpack 打包的结果体积太大

#### 提速策略
##### 不要让 loader 做太多事情。
最常见的优化方式是，用`include`或`exclude`来帮我们避免不必要的转译。
除此之外，如果我们选择开启缓存将转译结果缓存至文件系统，如下面的代码至少可以将`babel-loader`的工作效率提升两倍。
```js
loader: 'babel-loader?cacheDirectory=true'
```

##### 打包第三方库

第三方库`node_modules`，非常大，却又不可或缺。`Externals`一些情况下会引发重复打包的问题；而`CommonsChunkPlugin`每次构建时都会重新构建一次`vendor`，
推荐使用`DllPlugin`处理第三方库。这个插件会把第三方库单独打包到一个文件中，这个文件就是一个单纯的依赖库。这个依赖库不会跟着你的业务代码一起被重新打包，
只有当依赖自身发生版本变化时才会重新打包。

基于 dll 专属的配置文件，打包 dll 库：
```js
module.exports = {
    entry: {
      // 依赖的库数组
      vendor: [
        'prop-types',
        'babel-polyfill',
        'react',
        'react-dom',
        'react-router-dom',
      ]
    },
    output: {
      path: path.join(__dirname, 'dist'),
      filename: '[name].js',
      library: '[name]_[hash]',
    },
    plugins: [
      new webpack.DllPlugin({
        // DllPlugin的name属性需要和libary保持一致
        name: '[name]_[hash]',
        path: path.join(__dirname, 'dist', '[name]-manifest.json'),
        // context需要和webpack.config.js保持一致
        context: __dirname,
      }),
    ],
}
```

运行这个配置文件，`dist`文件夹里会出现这样两个文件`vendor-manifest.json`（描述每个第三方库对应的具体路径），`vendor.js`（第三方库打包的结果）。

`webpack.config.js`里针对`dll`稍作配置：
```js
module.exports = {
  mode: 'production',
  // 编译入口
  entry: {
    main: './src/index.js'
  },
  // 目标文件
  output: {
    path: path.join(__dirname, 'dist/'),
    filename: '[name].js'
  },
  // dll相关配置
  plugins: [
    new webpack.DllReferencePlugin({
      context: __dirname,
      // manifest就是我们第一步中打包出来的json文件
      manifest: require('./dist/vendor-manifest.json'),
    })
  ]
}
```

##### 将 loader 由单进程转为多进程
webpack 是单线程的，但是可以使用`Happypack`把任务分解给多个子进程去并发执行。
```js
const HappyPack = require('happypack')
// 手动创建进程池
const happyThreadPool =  HappyPack.ThreadPool({ size: os.cpus().length })

module.exports = {
  module: {
    rules: [
      ...
      {
        test: /\.js$/,
        // 问号后面的查询参数指定了处理这类文件的HappyPack实例的名字
        loader: 'happypack/loader?id=happyBabel',
        ...
      },
    ],
  },
  plugins: [
    ...
    new HappyPack({
      // 这个HappyPack的“名字”就叫做js，和楼上的查询参数遥相呼应
      id: 'js',
      // 指定进程池
      threadPool: happyThreadPool,
      loaders: ['babel-loader?cacheDirectory']
    })
  ],
}
```

#### 构建结果体积压缩
##### 找出导致体积过大的原因
[webpack-bundle-analyzer](https://www.npmjs.com/package/webpack-bundle-analyzer)一个非常好用的包组成可视化工具，
会以矩形树图的形式将包内各个模块的大小和依赖关系呈现出来。
```js
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

module.exports = {
  plugins: [
    new BundleAnalyzerPlugin()
  ]
}
```

##### 拆分资源
参考`DllPlugin`。

##### 删除冗余代码
从 webpack2 开始，webpack 原生支持了 ES6 的模块系统，并基于此推出了`Tree-Shaking`。
可以在编译的过程中获悉哪些模块并没有真正被使用，这些没用的代码，在最后打包的时候会被去除。但是它更适合用来处理模块级别的冗余代码。

更细粒度的冗余代码的去除，往往会被整合进 JS 或 CSS 的压缩或分离过程中。webpack3 可以使用`UglifyJsPlugin`，但是
在 webpack4 中，我们是通过配置`optimization.minimize`与`optimization.minimizer`来自定义压缩相关的操作的。

##### 按需加载
也就是一次不加载完所有的文件内容，只加载此刻需要用到的那部分。可以参考`vue-router`按需加载的方法。

#### Gzip
开启 Gzip，只需在你的 request headers 中加上这么一句`accept-encoding:gzip`。

HTTP 压缩就是以缩小体积为目的，对 HTTP 内容进行重新编码的过程，Gzip 的内核就是 Deflate。

什么时候用 Gzip？

如果你手上的项目是 1k、2k 的小文件，确实不要要，但是对于具备一定规模的项目文件，实践证明，这种情况下压缩和解压带来的时间开销相对于传输过程中节省下的时间开销来说，可以说是微不足道的。

Gzip 压缩背后的原理，是在一个文本文件中找出一些重复出现的字符串、临时替换它们，从而使整个文件变小。根据这个原理，文件中代码的重复率越高，那么压缩的效率就越高，
使用 Gzip 的收益也就越大。反之亦然。

webpack 的 Gzip 和服务端的 Gzip，Webpack 中 Gzip 压缩操作的存在，事实上就是为了在构建过程中去做一部分服务器的工作，为服务器分压。

### 图片优化
图片优化是前端性能优化必不可少的环节。

对于图片优化，压缩图片的体积，会牺牲一部分成像的质量，要寻找一个平衡点。

在计算机中，像素用二进制数来表示。不同的图片格式中像素与二进制位数之间的对应关系是不同的。一个像素对应的二进制位数越多，它可以表示的颜色种类就越多，成像效果也就越细腻，文件体积相应也会越大。

一个二进制位表示两种颜色（0|1 对应黑|白），如果一种图片格式对应的二进制位数有 n 个，那么它就可以呈现 2^n 种颜色。

#### 不同业务场景下的图片方案选型

##### JPEG/JPG
JPG 最大的特点是有损压缩，是一种高质量的压缩方式，以 24 位存储单个图，适用于呈现色彩丰富的图片，在我们日常开发中，JPG 图片经常作为大的背景图、轮播图或 Banner 图出现。

不支持透明度处理，处理矢量图形和 Logo 等线条感较强、颜色对比强烈的图像时，人为压缩导致的图片模糊会相当明显。

##### PNG-8 与 PNG-24
一种无损压缩的高保真的图片格式。8 和 24，这里都是二进制数的位数。比 JPG 更强的色彩表现力，对线条的处理更加细腻，对透明度有良好的支持。
主要用它来呈现小的 Logo、颜色简单且对比强烈的图片或背景等。

体积太大。

追求最佳的显示效果、并且不在意文件体积大小时，是推荐使用 PNG-24 的。

##### SVG
一种基于 XML 语法的图像格式。它和本文提及的其它图片种类有着本质的不同：SVG 对图像的处理不是基于像素点，而是是基于对图像的形状描述。
SVG 与 PNG 和 JPG 相比，文件体积更小，可压缩性更强。

SVG 是文本文件，我们既可以像写代码一样定义 SVG，把它写在 HTML 里、成为 DOM 的一部分，也可以把对图形的描述写入以 .svg 为后缀的独立文件

写入 HTML：
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title></title>
</head>
<body>
    <svg xmlns="http://www.w3.org/2000/svg"   width="200" height="200">
        <circle cx="50" cy="50" r="50" />
    </svg>
</body>
</html>
```

SVG 写入独立文件后引入 HTML：
```html
<img src="文件名.svg" alt="">
```

##### Base64
Base64 并非一种图片格式，而是一种编码方式。Base64 和雪碧图一样，是作为小图标解决方案而存在的。

雪碧图：一种将小图标和背景图像合并到一张图片上，然后利用 CSS 的背景定位来显示其中的每一部分的技术。被运用于众多使用大量小图标的网页应用之上。它可取图像的一部分来使用，
使得使用一个图像文件替代多个小文件成为可能。相较于一个小图标一个图像文件，单独一张图片所需的 HTTP 请求更少，对内存和带宽更加友好。

Base64 是作为雪碧图的补充而存在的。Base64 是一种用于传输 8Bit 字节码的编码方式，通过对图片进行 Base64 编码，我们可以直接将编码结果写入 HTML 或者写入 CSS，
从而减少 HTTP 请求的次数。

什么时候使用 Base64：
- 图片的实际尺寸很小（Base64 编码后，图片大小会膨胀为原文件的 4/3）
- 图片无法以雪碧图的形式与其它小图结合（合成雪碧图仍是主要的减少 HTTP 请求的途径，Base64 是雪碧图的补充）
- 图片的更新频率非常低（不需我们重复编码和修改文件内容，维护成本较低）

##### WebP
是 Google 专为 Web 开发的一种旨在加快图片加载速度的图片格式，它支持有损压缩和无损压缩。
WebP 像 JPEG 一样对细节丰富的图片信手拈来，像 PNG 一样支持透明，像 GIF 一样可以显示动态图片——它集多种图片文件格式的优点于一身。

WebP 是 2010 年被提出，目前的兼容性不是很好。和编码 JPG 文件相比，编码同样质量的 WebP 文件会占用更多的计算资源。

### 浏览器缓存
浏览器缓存是一种操作简单、效果显著的前端性能优化手段。

浏览器缓存机制有四个方面，它们按照获取资源时请求的优先级依次排列如下：
1. Memory Cache
2. Service Worker Cache
3. HTTP Cache
4. Push Cache

#### HTTP 缓存
分为强缓存和协商缓存。在命中强缓存失败的情况下，才会走协商缓存。

##### 强缓存

强缓存是利用 http 头中的`Expires`和`Cache-Control`两个字段来控制的。

在 Response Headers 中将过期时间写入`expires`字段实现强缓存`expires: Wed, 11 Sep 2019 16:12:18 GMT`，`expires`是一个时间戳。
当向服务器请求资源，浏览器就会先对比本地时间和 expires 的时间戳，如果本地时间小于`expires`设定的过期时间，那么就直接去缓存中取这个资源。
`expires`大的问题在于对“本地时间”的依赖。如果服务端和客户端的时间设置可能不同，或者我直接手动去把客户端的时间改掉，那么 expires 将无法达到我们的预期。

使用`Cache-Control`替代`expires`，继续使用 expires 的唯一目的就是向下兼容。`cache-control: max-age=31536000`通过`max-age`来控制资源的有效期。
`max-age`是一个时间长度。在本例中，`max-age`是`31536000`秒，表示该资源在`31536000`秒以后失效。

当`Cache-Control`与`expires`同时出现时，我们以`Cache-Control`为准。

###### no-store与no-cache

我们为资源设置Cache-Control 为 no-cache 后，每一次发起请求都不会再去询问浏览器的缓存情况，而是直接向服务端去确认该资源是否过期。

no-store 比较绝情，顾名思义就是不使用任何缓存策略。在 no-cache 的基础上，它连服务端的缓存确认也绕开了，只允许你直接向服务端发送请求、并下载完整的响应。

##### 协商缓存
协商缓存依赖于服务端与浏览器之间的通信。浏览器需要向服务器去询问缓存的相关信息，进而判断是重新发起请求、下载完整的响应，还是从本地获取缓存的资源。
如果服务端提示缓存资源未改动（Not Modified），资源会被重定向到浏览器缓存，这种情况下网络请求对应的状态码是 304。

如果我们启用了协商缓存，首次请求时随着 Response Headers 返回时会带上`Last-Modified`（`Last-Modified: Fri, 27 Oct 2017 06:35:57 GMT`）。

随后我们每次请求时，会带上一个叫`If-Modified-Since`的时间戳字段，它的值正是上一次 response 返回给它的`last-modified`值（If-Modified-Since: Fri, 27 Oct 2017 06:35:57 GMT）。

服务器接收到这个时间戳后，会比对该时间戳和资源在服务器上的最后修改时间是否一致，从而判断资源是否发生了变化。如果发生了变化，就会返回一个完整的响应内容，
并在 Response Headers 中添加新的 Last-Modified 值；否则，返回如上图的 304 响应，Response Headers 不会再添加 Last-Modified 字段。

问题：
1. 如果编辑了文件，但文件的内容没有改变，仍然通过最后编辑时间进行判断，就是错误的。
2. 由于 If-Modified-Since 只能检查到以秒为最小计量单位的时间差，所以当我们修改文件的速度过快时（比如花了 100ms 完成了改动）
该重新请求的时候，反而没有重新请求了。

Etag 是由服务器为每个资源生成的唯一的标识字符串，这个标识字符串是基于文件内容编码的，只要文件内容不同，它们对应的 Etag 就是不同的。

Etag 和 Last-Modified 类似，当首次请求时，我们会在响应头里获取到一个最初的标识符字符串（`ETag: W/"2a3b-1602480f459"`）。

下一次请求时，请求头里就会带上一个值相同的、名为`if-None-Match`的字符串供服务端比对了（`If-None-Match: W/"2a3b-1602480f459"`）。

Etag 的生成过程需要服务器额外付出开销，会影响服务端的性能，这是它的弊端。

Etag 和 Last-Modified 同时存在时，以 Etag 为准。

##### 缓存决策流程

当我们的资源内容不可复用时，直接为 Cache-Control 设置 no-store，拒绝一切形式的缓存；否则考虑是否每次都需要向服务器进行缓存有效确认，如果需要，那么设 Cache-Control
的值为 no-cache；否则考虑该资源是否可以被代理服务器缓存，根据其结果决定是设置为 private 还是 public；然后考虑该资源的过期时间，设置对应的 max-age 和 s-maxage 值；
最后，配置协商缓存需要用到的 Etag、Last-Modified 等参数。

#### MemoryCache
内存中的缓存，浏览器最先尝试去命中的，响应速度最快的缓存。进程结束后，缓存消失。

哪些文件会被放入内存？
有随机性，Base64 格式的图片，几乎永远可以被塞进 memory cache，体积不大的 JS、CSS 文件，也有较大地被写入内存的几率。

#### Service Worker Cache
Service Worker 是一种独立于主线程之外的 Javascript 线程。脱离于浏览器窗体，因此无法直接访问 DOM。可以帮我们实现离线缓存、消息推送和网络代理等功能。

#### Push Cache
指 HTTP2 在 server push 阶段存在的缓存。

- 浏览器只有在 Memory Cache、HTTP Cache 和 Service Worker Cache 均未命中的情况下才会去询问 Push Cache。
- Push Cache 是一种存在于会话阶段的缓存，当 session 终止时，缓存也随之释放。
- 不同的页面只要共享了同一个 HTTP2 连接，那么它们就可以共享同一个 Push Cache。

### 本地存储
#### cookie
Cookie 说白了就是一个存储在浏览器里的一个小小的文本文件，它附着在 HTTP 请求上，在浏览器和服务器之间“飞来飞去”。它可以携带用户信息，
当服务器检查 Cookie 的时候，便可以获取到客户端的状态。

问题：
1. 有体积上限，最大只能有 4KB
2. Cookie 是紧跟域名的，通过响应头里的`Set-Cookie`指定要存储的`Cookie`值（`Set-Cookie: name=xiuyan; domain=example.me`）。
3. 同一个域名下的所有请求，都会携带 Cookie，这样的不必要的 Cookie 带来的开销带来巨大的性能浪费。

#### Web Storage
浏览器的数据存储机制，分为 Local Storage 与 Session Storage。存储容量可以达到 5-10M 之间。

区别：
- 生命周期：Local Storage 是持久化的本地存储，存储在其中的数据是永远不会过期的，使其消失的唯一办法是手动删除，
Session Storage 是临时性的本地存储，它是会话级别的存储，当会话结束（页面被关闭）时，存储内容也随之被释放。
- 作用域：Local Storage、Session Storage 和 Cookie 都遵循同源策略。但 Session Storage 特别的一点在于，
即便是相同域名下的两个页面，只要它们**不在同一个浏览器窗口中打开**，那么它们的 Session Storage 内容便无法共享。

应用场景：
Local Storage 一般用来存储一些内容稳定的资源。如 Base64 格式的图片字符串，不经常更新的 CSS、JS 等静态资源。
Session Storage 更适合用来存储生命周期和它同步的会话级别的信息。

#### IndexDB
浏览器上的非关系型数据库。IndexDB 是没有存储上限的。
在 IndexDB 中，我们可以创建多个数据库，一个数据库中创建多张表，一张表中存储多条数据——这足以 hold 住复杂的结构性数据。

### CDN
前面说的浏览器缓存，本地缓存，都是在获取到资源之后做的，那么提高第一次获取资源的性能。就是 CDN。

CDN 的核心点有两个，一个是缓存，一个是回源。
“缓存”就是说我们把资源 copy 一份到 CDN 服务器上这个过程，“回源”就是说 CDN 发现自己没有这个资源（一般是缓存的数据过期了），转头向根服务器（或者它的上层服务器）去要这个资源的过程。

CDN 往往被用来存放静态资源。

非纯静态资源，丢到 CDN 上是不合适的。具体来说，当我打开某一网站之前，该网站需要通过权限认证等一系列手段确认我的身份、进而决定是否要把 HTML 页面呈现给我。
这种情况下 HTML 确实是静态的，但它和业务服务器的操作耦合。


#### 优化
静态资源往往并不需要 Cookie 携带什么认证信息。所以把静态资源和主页面置于不同的域名下，完美地避免了不必要的 Cookie 的出现。
大大的避免的性能的开销。

## 渲染层面

### 服务端渲染

我们先来了解客户端渲染的过程，服务端把渲染需要的静态文件发送给客户端，客户端加载过来之后，自己在浏览器里跑一遍 JS，根据 JS 的运行结果，生成相应的 DOM。

**页面上呈现的内容，你在 html 源文件里里找不到。**

服务端渲染：当用户第一次请求页面时，由服务器把需要的组件或页面渲染成 HTML 字符串，然后把它返回给客户端。客户端拿到手的，是可以直接渲染然后呈现给用户的 HTML 内容，
不需要为了生成 DOM 内容自己再去跑一遍 JS 代码。

服务端渲染通常是因为需要 SEO 才使用。

那么服务端渲染对性能有什么提升？
服务端渲染解决了一个非常关键的性能问题——首屏加载速度过慢。

#### Vue 实现服务端渲染
```js
const Vue = require('vue')
// 创建一个express应用
const server = require('express')()
// 提取出renderer实例
const renderer = require('vue-server-renderer').createRenderer()

server.get('*', (req, res) => {
  // 编写Vue实例（虚拟DOM节点）
  const app = new Vue({
    data: {
      url: req.url
    },
    // 编写模板HTML的内容
    template: `<div>访问的 URL 是： {{ url }}</div>`
  })

  // renderToString 是把Vue实例转化为真实DOM的关键方法
  renderer.renderToString(app, (err, html) => {
    if (err) {
      res.status(500).end('Internal Server Error')
      return
    }
    // 把渲染出来的真实DOM字符串插入HTML模板中
    res.end(`
      <!DOCTYPE html>
      <html lang="en">
        <head><title>Hello</title></head>
        <body>${html}</body>
      </html>
    `)
  })
})

server.listen(8080)
```

两个关键点：
1. `renderToString`方法
2. 把转化结果“塞”进模板里


### 浏览器背后的运行机制
见的浏览器内核，Trident（IE）、Gecko（火狐）、Blink（Chrome、Opera）、Webkit（Safari）。Blink 其实也是基于 Webkit 的。

内核内部的实现是下面这些功能模块相互配合协同工作进行的：
- HTML 解释器：将 HTML 文档经过词法分析输出 DOM 树。
- CSS 解释器：解析 CSS 文档, 生成样式规则。
- 图层布局计算模块：布局计算每个对象的精确位置和大小。
- 视图绘制模块：进行具体节点的图像绘制，将像素渲染到屏幕上。
- JavaScript 引擎：编译执行 Javascript 代码。

浏览器的渲染流程：
1. 解析 HTML，在这一步浏览器执行了所有的加载解析逻辑，在解析 HTML 的过程中发出了页面渲染所需的各种外部资源请求。
2. 计算样式，将识别并加载所有的 CSS 样式信息与 DOM 树合并，最终生成页面 render 树
3. 计算图层布局，页面中所有元素的相对位置信息，大小等信息均在这一步得到计算。
4. 绘制图层，在这一步中浏览器会根据我们的 DOM 代码结果，把每一个页面图层转换为像素，并对所有的媒体文件进行解码。
5. 整合图层，得到页面，合并合各个图层，将数据由 CPU 输出给 GPU 最终绘制在屏幕上。

#### 树
1. DOM 树
2. CSSOM 树
3. 渲染树
4. 布局渲染树
5. 绘制渲染树

上面的树分别对象浏览器的渲染流程的步骤。

渲染结束，之后每当一个新元素加入到这个 DOM 树当中，浏览器便会通过 CSS 引擎查遍 CSS 样式表，找到符合该元素的样式规则应用到这个元素上，然后再重新去绘制它。
重点来了，CSS 样式表规则的优化，提高让浏览器的查询速度。

#### CSS 优化

CSS 引擎查找样式表，**对每条规则都按从右到左的顺序去匹配。**例如：`#myList  li {}`，我们习惯从左到右阅读，可能以为浏览器也是，事实上，浏览器并不是。
所以上面的规则并不是先找到元素 id `myList`，从右到左匹配，开销是很大的。

所以 CSS 优化可以带来非常可观的性能提升，常用的方案：
- 避免使用通配符，只对需要用到的元素进行选择。
- 关注可以通过继承实现的属性，避免重复匹配重复定义。
- 少用标签选择器。如果可以，用类选择器替代
- id 和 class 选择器不应该被多余的标签选择器拖后腿。
- 减少嵌套。后代选择器的开销是最高的，因此我们应该尽量将选择器的深度降到最低。尽可能使用类来关联每一个标签元素。

#### CSS 与 JS 的加载顺序优化

HTML、CSS 和 JS，都具有阻塞渲染的特性。HTML 阻塞我们无法改变，没有HTML，拿来的DOM。

##### CSS 的阻塞
CSS 是阻塞的资源。浏览器在构建 CSSOM 的过程中，不会渲染任何已处理的内容。即便 DOM 已经解析完毕了，只要 CSSOM 不 OK，那么渲染这个事情就不 OK。
当我们开始解析 HTML 后、解析到 link 标签或者 style 标签时，CSS 才登场，CSSOM 的构建才开始。很多时候，DOM 不得不等待 CSSOM。

所以对于CSS 资源，应该将它尽早（将 CSS 放在 head 标签里）、尽快（启用 CDN 实现静态资源加载速度的优化）地下载到客户端，缩短首次渲染的时间。

##### JS 的阻塞
JS 引擎是独立于渲染引擎存在的。当 HTML 解析器遇到一个 script 标签时，它会暂停渲染过程，将控制权交给 JS 引擎。JS 引擎对内联的 JS 代码会直接执行，
对外部 JS 文件还要先获取到脚本、再进行执行。等 JS 引擎运行完毕，浏览器又会把控制权还给渲染引擎，继续 CSSOM 和 DOM 的构建。
因此与**其说是 JS 把 CSS 和 HTML 阻塞了，不如说是 JS 引擎抢走了渲染引擎的控制权。**

浏览器之所以让 JS 阻塞其它的活动，是因为它不知道 JS 会做什么改变，担心如果不阻止后续的操作，会造成混乱。但是我们是写 JS 的人，我们知道 JS 会做什么改变。假如我们可以确认一个 JS 文件
的执行时机并不一定非要是此时此刻，我们就可以通过对它使用 defer 和 async 来避免不必要的阻塞，这里我们就引出了外部 JS 的三种加载方式。

一般当我们的脚本与 DOM 元素和其它脚本之间的依赖关系不强时，我们会选用 async；当脚本依赖于 DOM 元素和其它脚本的执行结果时，我们会选用 defer。

### DOM 优化

#### DOM 优化思路
DOM 为什么这么慢？把 DOM 和 JavaScript 各自想象成一个岛屿，它们之间用收费桥梁连接。——《高性能 JavaScript》

JS 引擎和渲染引擎（浏览器内核）是独立实现的。当我们用 JS 去操作 DOM 时，本质上是 JS 引擎和渲染引擎之间进行了“跨界交流”。依赖了桥接接口作为“桥梁”。

过桥很慢，过桥之后，我们的更改操作带来的结果也很慢。当我们对 DOM 的修改会引发它外观（样式）上的改变时，就会触发回流或重绘。

这个过程本质上还是因为我们对 DOM 的修改触发了渲染树（Render Tree）的变化所导致的。

- 回流：当我们对 DOM 的修改引发了 DOM 几何尺寸的变化（比如修改元素的宽、高或隐藏元素等）时，浏览器需要重新计算元素的几何属性（其他元素的几何属性和位置也会因此受到影响），
然后再将计算的结果绘制出来。这个过程就是回流（也叫重排）。
- 重绘：当我们对 DOM 的修改导致了样式的变化、却并未影响其几何属性（比如修改了颜色或背景色）时，浏览器不需重新计算元素的几何属性、直接为该元素绘制新的样式（跳过了上图所示的回流环节）。
这个过程叫做重绘。

重绘不一定导致回流，回流一定会导致重绘。但这两个都带来了很大的性能开销。

##### 减少 DOM 操作
```js
for(var count=0;count<10000;count++){
  document.getElementById('container').innerHTML+='<span>我是一个小测试</span>'
}
```
上面的代码，首先每一次循环都获取了一次 container 元素，过路费浇太多。而且不必要的 DOM 更改太多了，每次循环都修改了 DOM。
优化：
```js
// 只获取一次container
let container = document.getElementById('container')
let content = ''
for(let count=0;count<10000;count++){
  // 先对内容进行操作
  content += '<span>我是一个小测试</span>'
}
// 内容处理好了,最后再触发DOM的更改
container.innerHTML = content
```

JS 层面的事情，JS 自己去处理，处理好了，再来找 DOM 打报告。这个思路，在 DOM Fragment 中体现得淋漓尽致。
上面的例子里，字符串变量 content 就扮演着一个 DOM Fragment 的角色。本质上都作为脱离了真实 DOM 树的容器出现，用于缓存批量化的 DOM 操作。

```js
let container = document.getElementById('container')
// 创建一个DOM Fragment对象作为容器
let content = document.createDocumentFragment()
for(let count=0;count<10000;count++){
  // span此时可以通过DOM API去创建
  let oSpan = document.createElement("span")
  oSpan.innerHTML = '我是一个小测试'
  // 像操作真实DOM一样操作DOM Fragment对象
  content.appendChild(oSpan)
}
// 内容处理好了,最后再触发真实DOM的更改
container.appendChild(content)
```

#### 异步更新策略
Vue 和 React 都实现了异步更新策略。都达到了减少 DOM 操作、避免过度渲染的目的。异步更新可以帮助我们避免过度渲染。

当我们需要在异步任务中实现 DOM 修改时，把它包装成 micro 任务是相对明智的选择，当我们需要在异步任务中实现 DOM 修改时，
把它包装成 micro 任务是相对明智的选择（`romise.resolve().then(task)`）。

优越性：
如果我们把这三个任务塞进异步更新队列里，它们会先在 JS 的层面上被批量执行完毕。当流程走到渲染这一步时，它仅仅需要针对有意义的计算结果操作一次 DOM——这就是异步更新的妙处。

##### Vue：nextTick

Vue 每次想要更新一个状态的时候，会先把它这个更新操作给包装成一个异步操作派发出去。这件事情，在源码中是由一个叫做 nextTick 的函数来完成的。
Vue 中每产生一个状态更新任务，它就会被塞进一个叫 callbacks 的数组（此处是任务队列的实现形式）中。这个任务队列在被丢进 micro 或 macro 队列之前，
会先去检查当前是否有异步更新任务正在执行（即检查 pending 锁）。如果确认 pending 锁是开着的（false），就把它设置为锁上（true），然后对当前 callbacks
数组的任务进行派发（丢进 micro 或 macro 队列）和执行。设置 pending 锁的意义在于保证状态更新任务的有序进行，避免发生混乱。

#### 回流与重绘

##### 哪些实际操作会导致重绘
触发了样式改变的 DOM 操作，都会引起重绘，比如背景色、文字色、可见性(可见性这里特指形如visibility: hidden这样不改变元素位置和存在性的、
单纯针对可见性的操作，注意与display:none进行区分)等。

##### 哪些实际操作会导致回流
- 改变 DOM 元素的几何属性，所有和它相关的节点（比如父子节点、兄弟节点等）的几何属性都需要进行重新计算，它会带来巨大的计算量。
- 改变 DOM 树的结构，节点的增减、移动等操作。
- 获取一些特定属性的值，像这样的属性：offsetTop、offsetLeft、 offsetWidth、offsetHeight、scrollTop、scrollLeft、scrollWidth、scrollHeight、clientTop、clientLeft、
clientWidth、clientHeight，是需要通过即时计算得到，因此浏览器为了获取这些值，也会进行回流。getComputedStyle 方法，或者 IE 里的 currentStyle 时，也会触发回流，一样的原理。


##### 规避回流与重绘
1. 缓存会导致回流或重绘的属性。
2. 避免逐条改变样式，使用类名去合并样式
3. 将 DOM “离线”
```js
let container = document.getElementById('container')
// 离线化
container.style.display = 'none'

// 离线化后在修改
container.style.width = '100px'
container.style.height = '200px'
container.style.border = '10px solid red'
container.style.color = 'red'

// 放回去
container.style.display = 'block'
```


##### Flush 队列
如果每次 DOM 操作都即时地反馈一次回流或重绘，那么性能上来说是扛不住的。于是它自己缓存了一个 flush 队列，把我们触发的回流与重绘任务都塞进去，
待到队列里的任务多起来、或者达到了一定的时间间隔，或者“不得已”的时候，再将这些任务一口气出队。
访问“即时性”属性时，浏览器会为了获得此时此刻的、最准确的属性值，而提前将 flush 队列的任务出队，这就是所谓的“不得已”时刻。

但是不是所有的浏览器都这么聪明。

## Lazy-Load
懒加载的实现思路，先把 style 内联样式中的背景图片属性设置为 none ，当出现在可视区域的瞬间，把背景图片属性从 none 变成一个在线图片的 URL。

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">
  <title>Lazy-Load</title>
  <style>
    .img {
      width: 200px;
      height:200px;
      background-color: gray;
    }
    .pic {
      // 必要的img样式
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="img">
      // 注意我们并没有为它引入真实的src
      <img class="pic" alt="加载中" data-src="./images/1.png">
    </div>
    <div class="img">
      <img class="pic" alt="加载中" data-src="./images/2.png">
    </div>
    <div class="img">
      <img class="pic" alt="加载中" data-src="./images/3.png">
    </div>
    <div class="img">
      <img class="pic" alt="加载中" data-src="./images/4.png">
    </div>
    <div class="img">
      <img class="pic" alt="加载中" data-src="./images/5.png">
    </div>
     <div class="img">
      <img class="pic" alt="加载中" data-src="./images/6.png">
    </div>
  </div>
</body>
</html>
```
两个关键的数值：一个是当前可视区域的高度，另一个是元素距离可视区域顶部的高度。

```js
<script>
    // 获取所有的图片标签
    const imgs = document.getElementsByTagName('img')
    // 获取可视区域的高度
    const viewHeight = window.innerHeight || document.documentElement.clientHeight // 兼容低版本 IE
    // num用于统计当前显示到了哪一张图片，避免每次都从第一张图片开始检查是否露出
    let num = 0
    function lazyload(){
        for(let i=num; i<imgs.length; i++) {
            // 用可视区域高度减去元素顶部距离可视区域顶部的高度
            let distance = viewHeight - imgs[i].getBoundingClientRect().top
            // 如果可视区域高度大于等于元素顶部距离可视区域顶部的高度，说明元素露出
            if(distance >= 0 ){
                // 给元素写入真实的src，展示图片
                imgs[i].src = imgs[i].getAttribute('data-src')
                // 前i张图片已经加载完毕，下次从第i+1张开始检查是否露出
                num = i + 1
            }
        }
    }
    // 监听Scroll事件
    window.addEventListener('scroll', lazyload, false);
</script>
```

## 节流（throttle）与防抖（debounce）
scroll 事件是一个非常容易被反复触发的事件，频繁触发回调导致的大量计算会引发页面的抖动甚至卡顿。
为了规避这种情况，throttle（事件节流）和 debounce（事件防抖）出现了。

### “节流”与“防抖”的本质

这两个东西都以闭包的形式存在。

它们通过对事件对应的回调函数进行包裹、以自由变量的形式缓存时间信息，最后用 setTimeout 来控制事件的触发频率。

### throttle
throttle 的中心思想在于：在某段时间内，不管你触发了多少次回调，我都只认第一次，并在计时结束时给予响应。

```js
// fn是我们需要包装的事件回调, interval是时间间隔的阈值
function throttle(fn, interval) {
  // last为上一次触发回调的时间
  let last = 0

  // 将throttle处理结果当作函数返回
  return function () {
      // 保留调用时的this上下文
      let context = this
      // 保留调用时传入的参数
      let args = arguments
      // 记录本次触发回调的时间
      let now = +new Date()

      // 判断上次触发的时间和本次触发的时间差是否小于时间间隔的阈值
      if (now - last >= interval) {
      // 如果时间间隔大于我们设定的时间间隔阈值，则执行回调
          last = now;
          fn.apply(context, args);
      }
    }
}

// 用throttle来包装scroll的回调
document.addEventListener('scroll', throttle(() => console.log('触发了滚动事件'), 1000))
```

### debounce
防抖的中心思想在于：我会等你到底。在某段时间内，不管你触发了多少次回调，我都只认最后一次。

我们对比 throttle 来理解 debounce：在throttle的逻辑里，“第一个人说了算”，它只为第一个乘客计时，时间到了就执行回调。而 debounce 认为，
“最后一个人说了算”，debounce 会为每一个新乘客设定新的定时器。

```js
// fn是我们需要包装的事件回调, delay是每次推迟执行的等待时间
function debounce(fn, delay) {
  // 定时器
  let timer = null

  // 将debounce处理结果当作函数返回
  return function () {
    // 保留调用时的this上下文
    let context = this
    // 保留调用时传入的参数
    let args = arguments

    // 每次事件被触发时，都去清除之前的旧定时器
    if(timer) {
        clearTimeout(timer)
    }
    // 设立新定时器
    timer = setTimeout(function () {
      fn.apply(context, args)
    }, delay)
  }
}

// 用debounce来包装scroll的回调
document.addEventListener('scroll', debounce(() => console.log('触发了滚动事件'), 1000))
```

### 用 Throttle 来优化 Debounce

debounce 的问题在于它“太有耐心了”。试想，如果用户的操作十分频繁——他每次都不等 debounce 设置的 delay 时间结束就进行下一次操作，
于是每次 debounce 都为该用户重新生成定时器，回调函数被延迟了不计其数次。频繁的延迟会导致用户迟迟得不到响应，用户同样会产生“这个页面卡死了”的观感。

打造一个“有底线”的 debounce:delay 时间内，我可以为你重新生成定时器；但只要delay的时间到了，我必须要给用户一个响应。

```js
// fn是我们需要包装的事件回调, delay是时间间隔的阈值
function throttle(fn, delay) {
  // last为上一次触发回调的时间, timer是定时器
  let last = 0, timer = null
  // 将throttle处理结果当作函数返回

  return function () {
      // 保留调用时的this上下文
      let context = this
      // 保留调用时传入的参数
      let args = arguments
      // 记录本次触发回调的时间
      let now = +new Date()
      // 判断上次触发的时间和本次触发的时间差是否小于时间间隔的阈值

      if (now - last < delay) {
      // 如果时间间隔小于我们设定的时间间隔阈值，则为本次触发操作设立一个新的定时器
         clearTimeout(timer)
         timer = setTimeout(function () {
            last = now
            fn.apply(context, args)
          }, delay)
      } else {
          // 如果时间间隔超出了我们设定的时间间隔阈值，那就不等了，无论如何要反馈给用户一次响应
          last = now
          fn.apply(context, args)
      }
    }

// 用新的throttle包装scroll的回调
document.addEventListener('scroll', throttle(() => console.log('触发了滚动事件'), 1000))
```

## 性能监测
性能监测目的是为了确定性能瓶颈，从而有的放矢地开展具体的优化工作。

性能监测方案主要有两种：可视化方案、可编程方案。

### Performance 开发者工具
Performance 是 Chrome 提供给我们的开发者工具，它呈现的数据具有实时性、多维度的特点，可以帮助我们很好地定位性能问题。
[Performance 官方文档](https://developers.google.com/web/tools/chrome-devtools/evaluate-performance/reference)

### LightHouse
Lighthouse 是一个开源的自动化工具，用于改进网络应用的质量。 你可以将其作为一个 Chrome 扩展程序运行，或从命令行运行。 为Lighthouse 提供一个需要审查的网址，它将针对此页面运行一连串的测试，然后生成一个有关页面性能的报告。

可以在 Chrome 的应用商店里下载一个 LightHouse。
也可以使用命令行`npm install -g lighthouse`。
[使用 Lighthouse 审查网络应用](https://developers.google.com/web/tools/lighthouse/?hl=zh-cn)

### Performance API
Performance API 是为了拿到真实的数据，才可以对它进行二次处理，去做一个更加深层次的可视化。

[MDN Performance API 介绍](https://developer.mozilla.org/zh-CN/docs/Web/API/Performance)

## 总结
- 网络层面的性能优化有两个方向：减少请求次数，减少单次请求所花费的时间。
  - webpack 优化
    - 构建过程提速（loader 少做不必要的事），打包第三方库（通过 DllPlugin 处理），将 loader 由单进程转为多进程（Happypack）。
    - 压缩体积，可视化工具（webpack-bundle-analyzer）找出导致体积过大的原因，拆分资源（DllPlugin），删除冗余代码
    （Tree-Shaking，optimization.minimize 与 optimization.minimizer），按需加载，HTTP 压缩（Gzip）
  - 图片优化，压缩图片的体积，是尽可能地去寻求一个质量与性能之间的平衡点。不同业务场景下的图片方案选型（JPEG/JPG、PNG、WebP、Base64、SVG 等）。
  - 浏览器缓存
    - HTTP 缓存 （Cache-Control 控制）
    - memory cache
    - service worker cache
    - push cache
  - 本地存储
    - cookie，同一个域名下的所有请求，都会携带 Cookie。这样的不必要的 Cookie 带来的开销将是无法想象的。
    - web storage
    - indexdb
  - CDN
    - 浏览器缓存，只能解决在第一次获取到资源之后的性能问题，那么CDN 可以解决第一次获取资源的性能问题。
    - 同一个域名下的请求会不分青红皂白地携带 Cookie，而静态资源往往并不需要 Cookie 携带什么认证信息。把静态资源和主页面置于不同的域名（CDN域名）下，
    完美地避免了不必要的 Cookie 的出现
- 渲染层面的优化
  - 服务端渲染，解决了首屏加载速度过慢。SEO。
  - 浏览器渲染的过程，CSS 优化，CSS 与 JS 的加载顺序优化
    - CSS 选择符是从右到左进行匹配的
    - 避免使用通配符，只对需要用到的元素进行选择。
    - 关注可以通过继承实现的属性，避免重复匹配重复定义。
    - 少用标签选择器。如果可以，用类选择器替代
    - id 和 class 选择器不应该被多余的标签选择器拖后腿。
    - 减少嵌套。后代选择器的开销是最高的，因此我们应该尽量将选择器的深度降到最低。尽可能使用类来关联每一个标签元素。
    - CSS 是阻塞渲染的资源。需要将它尽早、尽快地下载到客户端，以便缩短首次渲染的时间。
    - js 脚本，一般当我们的脚本与 DOM 元素和其它脚本之间的依赖关系不强时，我们会选用 async；当脚本依赖于 DOM 元素和其它脚本的执行结果时，我们会选用 defer。
  - DOM 优化，DOM 为什么这么慢？
    - 把 DOM 和 JavaScript 各自想象成一个岛屿，它们之间用收费桥梁连接。
    - 过桥很慢，到了桥对岸，我们的更改操作带来的结果也很慢。
  - 异步更新
    - Vue 中每产生一个状态更新任务，它就会被塞进一个叫 callbacks 的数组（此处是任务队列的实现形式）中。这个任务队列在被丢进 micro 或 macro 队列之前，
    会先去检查当前是否有异步更新任务正在执行（即检查 pending 锁）。如果确认 pending 锁是开着的（false），就把它设置为锁上（true），然后对当前 callbacks
    数组的任务进行派发（丢进 micro 或 macro 队列）和执行。设置 pending 锁的意义在于保证状态更新任务的有序进行，避免发生混乱。
  - 回流与重绘
    - 缓存会导致回流或重绘的属性。
    - 避免逐条改变样式，使用类名去合并样式
    - 将 DOM “离线”
- 应用
  - lazy-load，优化首屏体验
  - 节流和防抖
- 性能监测
