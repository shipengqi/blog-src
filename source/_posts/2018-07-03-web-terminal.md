---
title: Node.js 实现浏览器终端
date: 2018-07-03 12:57:58
categories: ["Node.js"]
---

最近要实现一个 web terminal，调研了几个开源的包，最后选择了 [Cloud Commander](http://cloudcmd.io/)。

<!-- more -->

选择 Cloud Commander 几个原因：

- 功能更丰富，支持 `vim`，支持查看多种文件(images, txt, video ...)，`Hot keys`，`Terminal`。
- 文档详细。
- 还在不断的完善，已经更新到 `v10.3.2`。

## 安装

```bash
npm install cloudcmd -g
```

因为 Cloud Commander 的 Terminal 功能默认是关闭的，如果使用需要安装 [gritty](https://github.com/cloudcmd/gritty) ：

```bash
npm i gritty -g
```

安装好之后要配置 `--terminal` 和 `--terminal-path`。

### 安装中的错误

如果碰到下面两种错误，都是因为权限引起的错误：
<img src="/images/web-terminal/error1.JPG" width="80%" height="">
<img src="/images/web-terminal/error2.JPG" width="80%" height="">

解决：

```bash
npm config set user 0
npm config set unsafe-perm true
npm install cloudcmd -g
npm install gritty -g
```

## 简单使用

安装好之后直接运行 `cloudcmd` 就会打开一个默认的端口 `8000`，然后访问 `http://localhost:8000` 就可以了。

如果要使用 `terminal` 功能：

```bash
# 查看 gritty 的路径
gritty --path

# 输出
/usr/local/lib/node_modules/gritty

cloudcmd --terminal --terminal-path /usr/local/lib/node_modules/gritty --save
```

然后访问 `http://localhost:8000`：
<img src="/images/web-terminal/terminal1.JPG" width="80%" height="">
<img src="/images/web-terminal/terminal2.JPG" width="80%" height="">

关于更多配置使用查看 [Cloud Commander 官方文档](http://cloudcmd.io/)。
如果只是想实现 terminal 功能，可以直接安装使用 [gritty](https://github.com/cloudcmd/gritty)。

## 与 Express 集成

### gritty 与 Express 集成

```bash
npm i gritty socket.io express --save
```

创建服务端：

```javascript
const gritty = require('gritty');
const http = require('http');
const express = require('express');
const io = require('socket.io');

const app = express();
const server = http.createServer(app);
const socket = io.listen(server);

const port = 1337;

app.use(gritty())
app.use(express.static(__dirname));

gritty.listen(socket);
server.listen(port);
```

页面 `index.html`：

```html
<div class="gritty"></div>
<script src="/gritty/gritty.js"></script>
<script>
    gritty('.gritty');
</script>
```

### cloudcmd 与 Express 集成

```bash
npm i cloudcmd socket.io express --save
```

创建服务端：

```javascript
const http = require('http');
const cloudcmd = require('cloudcmd');
const io = require('socket.io');
const app = require('express')();

const port = 1337;
const prefix = '/cloudcmd';

const server = http.createServer(app);
const socket = io.listen(server, {
    path: `${prefix}/socket.io`
});

const config = {
    prefix // base URL or function which returns base URL (optional)
};

const plugins = [
    __dirname + '/plugin.js'
];

const filePicker = {
    data: {
        FilePicker: {
            key: 'key'
        }
    }
};

// override option from json/modules.json
const modules = {
    filePicker,
};

app.use(cloudcmd({
    socket,  // used by Config, Edit (optional) and Console (required)
    config,  // config data (optional)
    plugins, // optional
    modules, // optional
}));

server.listen(port);
```
