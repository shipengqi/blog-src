---
title: Node.js 生成 API 文档
date: 2018-03-28 14:22:02
categories: ["Node.js"]
---

[JSDoc](http://usejsdoc.org/) 是一个根据 Javascript 文件中的代码注释，生成 API 文档的工具。

<!-- more -->

## 简单使用

JSDoc 注释放置在方法或函数声明之前，它必须以 `/ **` 开始，其他以 `/*`，`/***` 或者超过 3 个星号的注释，都将被 JSDoc 解析器忽略。例如一下代码：

```javascript
/**
 * Student类，学生.
 * @constructor
 * @param {string} name - 学生姓名.
 * @param {string} address - 学生家庭住址.
 */
function Student(name, address) {
    this.name = name;
    this.address = address;
}
Student.prototype={
    /**
     * 获取学生的住址
     * @returns {string|*}
     */
    getAddress: function(){
        return this.address;
    }
};
```

上面的代码中，以 `@` 开头的是 JSDoc 的。因为 JSDoc 考虑向后兼容，所以一些注释标签存在别名。 比如 `@param` 有两个别名：`@arg`，`@argument`。

## 标签

关于标签参考：

- [JSDoc 中文文档](http://www.css88.com/doc/jsdoc/tags.html)
- [JSDoc 官网](http://usejsdoc.org/)

## 生成 Markdown 文档

### 安装依赖

```bash
npm install -g jsdoc-to-markdown
```

### 使用

如 `docs.sh` 文件：

```bash
PROJECT_ROOT="$PWD"
MARKDOWN_DOCS_DIR="${PROJECT_ROOT}/docs"

node_modules/.bin/jsdoc2md \
  --files "lib/**/*.js" \
  > "${MARKDOWN_DOCS_DIR}/api_docs.md"
```

运行 `docs.sh` 会在当前目录下的 `docs` 目录生成 `api_docs.md` 文件。

查看命令帮助：

```bash
jsdoc2md --help
```
