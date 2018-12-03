# blog-src

:see_no_evil: :books:  My blog source code, builded by [Hexo](https://github.com/hexojs/hexo).

## Requirements
- Node.js

## Usage
```bash
#全局安装 Hexo
yarn global install hexo-cli # npm install -g hexo-cli

#安装依赖
yarn install # or npm install

#启动
./run.sh
```

**Options**
```bash
Options:
  --help
    Display this help screen

  --start
    启动服务

  --port
    指定监听的端口

  --deploy
    部署到github

  --proxy
    配置代理，参数可选，没有参数即使用默认代理。
    配合deploy使用, e.g: --proxy="http://proxy.com"
    注意"="必须有
```

## 所用到的插件
- [hexo-theme-next](https://github.com/theme-next/hexo-theme-next) 这应该是使用`Hexo`搭建博客最常用的主题插件
- [hexo-generator-feed](https://github.com/hexojs/hexo-generator-feed) 使用`Hexo`生成的`Feed`链接，配置`RSS`
- [hexo-algolia](https://github.com/oncletom/hexo-algolia) `Algolia`搜索服务
- [hexo-neat](https://github.com/rozbo/hexo-neat) 自动压缩静态文件
- [hexo-qiniu-sync](https://github.com/gyk001/hexo-qiniu-sync) 自动上传到静态文件[七牛云](https://portal.qiniu.com)
- [hexo-generator-sitemap](https://github.com/hexojs/hexo-generator-sitemap) 和 [hexo-generator-baidu-sitemap](https://github.com/coneycode/hexo-generator-baidu-sitemap) 用来[生成`sitemap`](https://www.shipengqi.top/2018/07/18/hexo-seo2)，用于`SEO`
- [hexo-baidu-url-submit](https://github.com/huiwang/hexo-baidu-url-submit) 主动推送`Hexo`博客新链接至百度搜索引擎

## Reading list
- 数据结构与算法
  - 啊哈！算法
  - [Javascript algorithms](https://github.com/trekhleb/javascript-algorithms)
  - 剑指 Offer
  - Lodash source code
- 操作系统
  - [Java 程序员眼中的 Linux](https://github.com/judasn/Linux-Tutorial)
  - 鸟哥的 Linux 私房菜
- 计算机网络
  - TCP/IP 详解
  - 极客时间 RPC 深入理解
  - 极客时间 趣谈网络协议
  - [socket.io source code](https://github.com/socketio/socket.io)
- 面向对象
  - 设计模式
- 数据库
  - MySQL 必知必会
  - 高性能 MySQL
  - 小册 Redis 深度历险
  - Redis 设计与实现
- Javascript, HTML, CSS
  - 你不知道的 Javascript
  - Javascript 函数式编程
  - [JS 深入系列](https://github.com/mqyqingfeng/Blog)
  - [JS 函数式编程指南](https://github.com/llh911001/mostly-adequate-guide-chinese)
  - [30 seconds of code](https://github.com/30-seconds/30-seconds-of-code)，Javascript CSS 相关知识，技巧，面试题。
  - [33 js concepts 中文版](https://github.com/stephentian/33-js-concepts)
  - [前端指南](https://github.com/nanhupatar/FEGuide)
  - [V8 引擎](https://github.com/justjavac/v8.js.cn)
  - CSS 揭秘
  - 小册 大厂H5
  - 小册 前端面试指南
  - 小册 前端优化原理
  - [前端精读周刊](https://github.com/dt-fe/weekly)
- Vue
  - Vue source code
    - [Vue design](https://github.com/HcySunYang/vue-design)
    - [Vue.js 源码解析](https://github.com/answershuto/learnVue)
    - [Vue Analysis](https://github.com/ustbhuangyi/vue-analysis)
  - [Vue CLI](https://cli.vuejs.org/zh/)
    - 小册 Vue CLI3
  - [Vue SSR](https://ssr.vuejs.org/zh/)
- Node.js
  - [Node.js Source code](https://github.com/nodejs/node)
  - [Node.js 调试指南](https://github.com/nswbmw/node-in-debugging)
  - [Node 性能优化](https://segmentfault.com/a/1190000007621011)
  - [profiler](https://segmentfault.com/a/1190000012414666)
  - [深入理解Node.js：核心思想与源码分析](https://github.com/yjhjstz/deep-into-node)
  - [Nodejs学习笔记](https://github.com/chyingp/nodejs-learning-guide)
  - [Nodejs笔记](https://github.com/peze/someArticle)
  - Node.js：来一打C++扩展
  - Express, [Koa source code](https://juejin.im/post/5be3a0a65188256ccc192a87)
  - Hubot source code
  - Unit test (Mocha, nyc)
- Go
  - [Go 语言圣经](https://docs.hacknode.org/gopl-zh/index.html)
  - [Go 语言高级编程](https://chai2010.gitbooks.io/advanced-go-programming-book/content/)
  - Go 并发编程实战
  - Go 语言学习笔记
  - 极客时间 Go 语言核心三十六讲
  - 小册 Go 搭建企业级Web
- 系统设计
  - [System design primer](https://github.com/donnemartin/system-design-primer)
  - 人人都是架构师
  - 微服务架构与实践
  - 微服务设计
  - 架构解密:从分布式到微服务
  - 架构探险:从零开始写分布式服务架构
  - 亿级流量网站架构核心技术
  - 阿里技术 双十一
  - 极客时间 微服务核心二十讲
  - 极客时间 秒杀系统设计
  - 极客时间 推荐系统三十六式
  - 极客时间 从零开始学架构
  - 推荐系统实战
- 工具
  - 小册 webpack 定制前端开发环境
  - 深入剖析 Kubernetes
  - Kubernetes 部署
- 其它
  - [Weex](http://weex.apache.org/cn/guide/)
  - [MiniProgram](https://developers.weixin.qq.com/miniprogram/dev/)
    - 小册 微信小程序开发入门
    - 小册 微信小游戏
- Recommendations
  - [JavaGuide 包含了Java,架构,数据库,算法，协议等相关知识](https://github.com/Snailclimb/JavaGuide)
  - [Computer Science Learning Notes](https://github.com/CyC2018/CS-Notes)
  - [技能图谱](https://github.com/TeamStuQ/skill-map)
  - [九部知识库](https://github.com/frontend9/fe9-library)
  - [前端开发月报](https://github.com/jsfront/month)
  - [掘金翻译计划](https://github.com/xitu/gold-miner)
  - [免费的计算机编程类中文书籍](https://github.com/justjavac/free-programming-books-zh_CN?utm_source=gold_browser_extension)
  - 掘金 收藏 list

## TODO
- 优化：[七牛云静态资源存储插件](https://github.com/gyk001/hexo-qiniu-sync)
