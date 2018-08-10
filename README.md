# blog-src

My blog source code.

## Requirements
- NodeJs

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
- [hexo-theme-next](https://github.com/theme-next/hexo-theme-next) 这应该是使用[Hexo](https://github.com/hexojs/hexo)搭建博客最常用的主题插件
- [hexo-generator-feed](https://github.com/hexojs/hexo-generator-feed) 使用`Hexo`生成的`Feed`链接，配置`RSS`
- [hexo-algolia](https://github.com/oncletom/hexo-algolia) `Algolia`搜索服务
- [hexo-neat](https://github.com/rozbo/hexo-neat) 自动压缩静态文件
- [hexo-qiniu-sync](https://github.com/gyk001/hexo-qiniu-sync) 自动上传到静态文件[七牛云](https://portal.qiniu.com)
- [hexo-generator-sitemap](https://github.com/hexojs/hexo-generator-sitemap)和[hexo-generator-baidu-sitemap](https://github.com/coneycode/hexo-generator-baidu-sitemap) [生成`sitemap`](https://www.shipengqi.top/2018/07/18/hexo-seo2)的插件，用于`SEO`
- [hexo-baidu-url-submit](https://github.com/huiwang/hexo-baidu-url-submit) 主动推送Hexo博客新链接至百度搜索引擎

## TODO
- Articles
  - Javascript basics, HTML, CSS, Vue.js Virtual DOM
  - Webpack Usage
  - Redis, cache
  - Express, Koa source code
  - NodeJs Unit test (Mocha, nyc)
  - TCP, WS, RPC
  - Hubot source code
  - Docker, Kubernetes
  - Go
- 优化
  - 七牛云静态资源存储
    - https://github.com/gyk001/hexo-qiniu-sync
