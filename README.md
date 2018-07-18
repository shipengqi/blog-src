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

## TODO
- Add文章
  - Javascript basics, HTML, CSS, Vue.js虚拟DOM
  - Webpack 使用
  - Redis, cache
  - Express, Koa source code
  - NodeJs Unit test (Mocha, nyc)
  - TCP, WS, RPC
  - Hubot source code
  - Docker, Kubernetes
  - Go
