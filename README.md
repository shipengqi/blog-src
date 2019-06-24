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
    配合 deploy 使用, e.g: --proxy="http://proxy.com"
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
[Summary](./SUMMARY.md)


## 主题
### next
`next` 主题需要修改 站点配置：
```yml
# Site
title: Learning
subtitle: Learning
language: zh-Hans

## Themes: https://hexo.io/themes/
theme: next

#search:
#  path: search.xml
#  field: post
#  content: true

algolia:
  applicationID: '07FOXYZ6PF'
  indexName: 'blog'
  apiKey: 'fff267b07b3a0db8d496a17fe3601667'
  chunkSize: 5000
```

`next` 使用 `algolia` 实现搜索功能。

### cactus
`cactus` 主题需要修改 站点配置：
```yml
# Site
title: Learning
subtitle: Learning
language: en

## Themes: https://hexo.io/themes/
theme: cactus

search:
  path: search.xml
  field: post
  content: true

#algolia:
#  applicationID: '07FOXYZ6PF'
#  indexName: 'blog'
#  apiKey: 'fff267b07b3a0db8d496a17fe3601667'
#  chunkSize: 5000

#compress
neat_enable: false
neat_html:
  enable: true
  exclude:
neat_css:
  enable: true
  exclude:
    - '*.min.css'
neat_js:
  enable: true
  mangle: true
  output:
  compress:
  exclude:
    - '*.min.js'
```

`cactus` 主题在 `source` 下增加了 `_data` 和 `search` 目录。

`cactus` 使用 `hexo-generator-search` 实现搜索功能。

## TODO
- 优化：[七牛云静态资源存储插件](https://github.com/gyk001/hexo-qiniu-sync)
