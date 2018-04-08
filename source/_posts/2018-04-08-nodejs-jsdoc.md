---
title: NodeJs 生成API文档
date: 2018-04-08 14:22:02
categories: ["NodeJs"]
---

jsdoc 是一个根据javascript文件中的代码注释，生成api文档的工具。

<!-- more -->

JSDoc注释放置在方法或函数声明之前，它必须以`/ **`开始，其他以`/*`，`/***`或者超过3个星号的注释，都将被JSDoc解析器忽略。例如一下代码：
``` javascript
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

上面的代码中，以`@`开头的是 JSDoc 的。因为JSDoc考虑向后兼容，所以一些注释标签存在别名。 比如@param有两个别名：`@arg`，`@argument`。