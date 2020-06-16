---
title: NPM scripts 使用
date: 2017-07-23 22:54:07
categories: ["Node.js"]
---

npm 脚本功能是最常用的功能之一。运行 `npm run <script_name>` 会执行当前项目的 `package.json` 中 `scripts` 属性下对应 `script_name` 的
脚本。

<!-- more -->
## 简单使用

使用 `scripts` 字段定义脚本命令。

``` javascript
"scripts": {
    "build": "node build.js"
}
```

使用 `npm run` 命令，就可以执行这段脚本:

``` bash
npm run build
```

## 原理

`npm run` 会创建一个 Shell，执行指定的命令，并**临时将 `node_modules/.bin` 加入 `PATH` 变量，执行结束后，再将 `PATH` 变量恢复原样**。
也就说 `node_modules/.bin` 子目录里面的脚本，都可以直接用脚本名调用。比如，当前项目的依赖里面有 `Mocha`，只要直接写 `mocha test` 就可以了。

```javascript
"test": "mocha test"
// 而不用写成下面这样。
"test": "./node_modules/.bin/mocha test"
```

npm 脚本的退出码，也遵守 Shell 脚本规则。如果退出码不是 0，npm 就认为这个脚本执行失败。

## 传参

向 npm 脚本传入参数，要使用 `--` 隔开，`--` 后面的内容都会原封不动地传给运行的命令。

```javascript
"test": "mocha test"
```

向上面的 `npm test` 命令传入参数，必须写成下面这样。

``` bash
npm test -- --reporter spec
```

也可以封装在 `package.json` 里面。

``` javascript
"test": "mocha --reporter spec"
```

## 钩子

在 `npm script` 中有两个钩子 `pre` 和 `post`。例如上面的 `test` 脚本：

``` javascript
"scripts":{
    "pretest": "echo run before the test script"
    "test": "mocha --reporter spec",
    "posttest": "echo run after the test script"
}
```

执行 `npm test` 的时候，会自动按照下面的顺序执行。

``` bash
npm run pretest && npm run test && npm run posttest
```

## 简写形式

四个常用的 npm 脚本有简写形式。

- `npm start` 是 `npm run start`
- `npm stop` 是 `npm run stop` 的简写
- `npm test` 是 `npm run test` 的简写
- `npm restart`

`npm restart` 是一个复合命令，它不单单执行 `prerestart`, `restart`, `postrestart` 具体的执行顺序如下：

1. prerestart
2. prestop
3. stop
4. poststop
5. restart
6. prestart
7. start
8. poststart
9. postrestart

## 环境变量

npm 脚本可以访问 `package.json` 中的变量。
通过 `process.env.npm_package_xxx` 可以获得，比如，下面是一个 `package.json`。

```javascript
{
  "name": "foo",
  "version": "1.2.5",
  "scripts": {
    "view": "node view.js"
  }
}

process.env.npm_package_name // foo
process.env.npm_package_version // 1.2.5
process.env.npm_package_scripts_view //node view.js
```

npm 脚本可以访问 npm 的配置变量。
通过 `process.env.npm_config_xxx` 可以获得，即 `npm config get xxx` 命令返回的值。
例如 `process.env.npm_config_user_email` 可以拿到 `user.email` 的值。
