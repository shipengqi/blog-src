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

## TODO
- Reading Scheme
  - Javascript, HTML, CSS
    - 你不知道的 Javascript
    - [JS 函数式编程指南](https://github.com/llh911001/mostly-adequate-guide-chinese)
    - [30 seconds of code](https://github.com/30-seconds/30-seconds-of-code)，Javascript CSS 相关知识，技巧，面试题。
    - [前端入门](https://github.com/e-f-e/fe-primary-tutorial)
  - Vue	
    - Vue source code
      - [Vue design](https://github.com/HcySunYang/vue-design)
      - [Vue.js 源码解析](https://github.com/answershuto/learnVue)
	  - [Vue Analysis](https://github.com/ustbhuangyi/vue-analysis)
    - [Vue CLI](https://cli.vuejs.org/zh/)
    - [Vue SSR](https://ssr.vuejs.org/zh/)
  - [Weex](http://weex.apache.org/cn/guide/)		
  - Node.js
    - [Node.js Source code](https://github.com/nodejs/node)
    - [Node.js 调试指南](https://github.com/nswbmw/node-in-debugging)
    - [Node 性能优化](https://segmentfault.com/a/1190000007621011)
    - [profiler](https://segmentfault.com/a/1190000012414666)
    - [深入理解Node.js：核心思想与源码分析](https://github.com/yjhjstz/deep-into-node)
    - [Nodejs学习笔记](https://github.com/chyingp/nodejs-learning-guide)
    - Express, Koa source code
    - Hubot source code
    - [socket.io source code](https://github.com/socketio/socket.io)
    - Lodash source code
    - Unit test (Mocha, nyc)
  - Go
    - [Go 语言圣经](https://docs.hacknode.org/gopl-zh/index.html)
    - [Go 语言高级编程](https://chai2010.gitbooks.io/advanced-go-programming-book/content/)
    - Go 并发编程实战
    - Go 语言学习笔记
  - Webpack Usage
    - 小册 webpack 定制前端开发环境
  - Redis, cache
    - 小册 Redis 深度历险
    - Redis 设计与实现
  - TCP, WS, RPC
    - TCP/IP 详解
    - 极客时间 RPC 深入理解
  - Docker, Kubernetes
  - [Javascript algorithms](https://github.com/trekhleb/javascript-algorithms)
  - [MiniProgram](https://developers.weixin.qq.com/miniprogram/dev/)
    - 小册 微信小程序开发入门
  - [System design primer](https://github.com/donnemartin/system-design-primer)
  - 架构
    - 人人都是架构师
    - 微服务架构与实践
    - 微服务设计
    - 架构解密:从分布式到微服务
    - 架构探险:从零开始写分布式服务架构
    - 亿级流量网站架构核心技术
    - 阿里技术 双十一
    - 极客时间 微服务
  - Linux 
    - 命令 curl awk [查找命令](http://www.ruanyifeng.com/blog/2009/10/5_ways_to_search_for_files_using_the_terminal.html?bsh_bid=223636115)
    - [Java 程序员眼中的 Linux](https://github.com/judasn/Linux-Tutorial)
  - Recommendations
    - [JavaGuide 包含了Java,架构,数据库,算法，协议等相关知识](https://github.com/Snailclimb/JavaGuide)
    - [技能图谱](https://github.com/TeamStuQ/skill-map)
    - [掘金翻译计划](https://github.com/xitu/gold-miner)
    - [免费的计算机编程类中文书籍](https://github.com/justjavac/free-programming-books-zh_CN?utm_source=gold_browser_extension)
- 优化
  - [七牛云静态资源存储插件](https://github.com/gyk001/hexo-qiniu-sync)
