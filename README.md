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
- 操作系统
  - 鸟哥的 Linux 私房菜
  - [Java 程序员眼中的 Linux](https://github.com/judasn/Linux-Tutorial)
- 计算机网络
  - 极客时间 趣谈网络协议
  - 极客时间 RPC 深入理解
  - TCP/IP 详解
  - [socket.io source code](https://github.com/socketio/socket.io)
- 数据库
  - [SQL教程](https://www.liaoxuefeng.com/wiki/001508284671805d39d23243d884b8b99f440bfae87b0f4000)
  - MySQL 必知必会
  - 高性能 MySQL
  - 小册 Redis 深度历险
  - Redis 设计与实现
- 面向对象
  - Javascript 设计模式
- 数据结构与算法
  - 啊哈！算法
  - [Javascript algorithms](https://github.com/trekhleb/javascript-algorithms)
  - 剑指 Offer
  - Lodash source code
- Javascript, HTML, CSS
  - 你不知道的 Javascript
  - 高性能 Javascript
  - Javascript 函数式编程
  - 小册 大厂H5
  - 小册 前端面试指南
  - 小册 前端优化原理
  - [JS 深入系列](https://github.com/mqyqingfeng/Blog)
  - [JS 函数式编程指南](https://github.com/llh911001/mostly-adequate-guide-chinese)
  - [30 seconds of code](https://github.com/30-seconds/30-seconds-of-code)，Javascript CSS 相关知识，技巧，面试题。
  - [33 js concepts 中文版](https://github.com/stephentian/33-js-concepts)
  - [前端知识集锦](https://github.com/KieSun/Front-end-knowledge)
  - [前端面试之道](https://github.com/InterviewMap/CS-Interview-Knowledge-Map)
  - [前端指南](https://github.com/nanhupatar/FEGuide)
  - [V8 引擎](https://github.com/justjavac/v8.js.cn)
  - CSS 揭秘
  - [CSS Inspiration](https://github.com/chokcoco/CSS-Inspiration)
  - [前端月刊](https://github.com/jsfront/month)
  - 前端监控 掘金收藏
- Vue
  - Vue source code
    - [Vue design](https://github.com/HcySunYang/vue-design)
    - [Vue.js 源码解析](https://github.com/answershuto/learnVue)
    - [Vue Analysis](https://github.com/ustbhuangyi/vue-analysis)
  - [Vue CLI](https://cli.vuejs.org/zh/)
    - 小册 Vue CLI3
  - [Vue SSR](https://ssr.vuejs.org/zh/)
  - 小册 Vue 组件精讲
  - 实战
    - [基于 vue2 + vuex 构建一个具有 45 个页面的大型单页面应用](https://github.com/bailicangdu/vue2-elm)
    - [基于vue2.0的实时聊天项目](https://github.com/hua1995116/webchat)
    - [vuejs仿网易云音乐](https://github.com/hua1995116/musiccloudWebapp)
- Node.js
  - [Node.js Source code](https://github.com/nodejs/node)
  - Node.js 核心模块
  - Node.js 内存管理与垃圾回收
  - [Node.js 调试指南](https://github.com/nswbmw/node-in-debugging)
  - [Node 性能优化](https://segmentfault.com/a/1190000007621011)
  - [Node.js 最佳实践](https://github.com/i0natan/nodebestpractices/blob/master/README.chinese.md)
  - [profiler](https://segmentfault.com/a/1190000012414666)
  - [深入理解Node.js：核心思想与源码分析](https://github.com/yjhjstz/deep-into-node)
  - [Nodejs学习笔记](https://github.com/chyingp/nodejs-learning-guide)
  - [Nodejs笔记](https://github.com/peze/someArticle)
  - Node.js：来一打C++扩展
  - Express, [Koa source code](https://juejin.im/post/5be3a0a65188256ccc192a87)
  - Hubot source code
  - Unit test (Mocha, nyc)
- Go
  - Go 并发编程实战
  - Go 语言学习笔记
  - [GO 入门指南](https://github.com/Unknwon/the-way-to-go_ZH_CN)
  - 极客时间 Go 语言核心三十六讲
  - 小册 Go 搭建企业级Web
  - Go 内存管理与垃圾回收
  - Go 并发调度
  - [Learn Go with tests](https://github.com/quii/learn-go-with-tests)
  - [Learning Go](https://github.com/mikespook/Learning-Go-zh-cn)
  - [Go 语言圣经](https://docs.hacknode.org/gopl-zh/index.html)
  - [Go 语言高级编程](https://chai2010.gitbooks.io/advanced-go-programming-book/content/)
- 系统设计
  - 极客时间 从零开始学架构
  - 极客时间 秒杀系统设计
  - 极客时间 推荐系统三十六式
  - 极客时间 从零开始学微服务
  - 极客时间 微服务核心二十讲
  - 架构师之路
  - 人人都是架构师
  - 架构解密:从分布式到微服务
  - 架构探险:从零开始写分布式服务架构
  - 亿级流量网站架构核心技术
  - 大型网站架构演进与性能优化
  - 架构整洁之道
  - 阿里技术 双十一
  - 推荐系统实战
  - 微服务架构与实践
  - 微服务设计
  - [System design primer](https://github.com/donnemartin/system-design-primer)
- 工具
  - 极客时间 深入剖析 Kubernetes
  - 小册 Kubernetes 上手到实践
  - 小册 webpack 定制前端开发环境
- 其它
  - [Weex](http://weex.apache.org/cn/guide/)
  - [MiniProgram](https://developers.weixin.qq.com/miniprogram/dev/)
    - 小册 微信小程序开发入门
    - 小册 微信小游戏
- Recommendations
  - [Java 架构图谱](https://github.com/xingshaocheng/architect-awesome) 
  - [Java 知识扫盲](https://github.com/doocs/advanced-java?utm_source=gold_browser_extension)
  - [JavaGuide 包含了Java,架构,数据库,算法，协议等相关知识](https://github.com/Snailclimb/JavaGuide)
  - [Computer Science Learning Notes](https://github.com/CyC2018/CS-Notes)
  - [技能图谱](https://github.com/TeamStuQ/skill-map)
  - [九部知识库](https://github.com/frontend9/fe9-library)
  - [掘金翻译计划](https://github.com/xitu/gold-miner)
  - [免费的计算机编程类中文书籍](https://github.com/justjavac/free-programming-books-zh_CN?utm_source=gold_browser_extension)
  - 掘金 收藏 list

## TODO
- 优化：[七牛云静态资源存储插件](https://github.com/gyk001/hexo-qiniu-sync)
https://github.com/yangwenmai/learning-golang
https://github.com/Miej/GoDeeper
