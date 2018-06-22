# blog-src

My blog source code.

## requirements
- NodeJs
- Hexo(全局安装)

## Usage
```bash
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
- Check port before starting up
  - [portscanner](https://github.com/baalexander/node-portscanner)
- Add
  - Javascript basics, HTML, CSS, Vue.js虚拟DOM
  - Redis, cache
  - Express, Koa source code
  - Mocha, Jtest
  - TCP, WS, RPC
  - Hubot
  - Docker, Kubernetes
  - Go
- SEO
  - https://hjptriplebee.github.io/hexo%E7%9A%84SEO%E6%96%B9%E6%B3%95.html/
