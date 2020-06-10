---
title: 关于 exports 和 module.exports
date: 2018-03-17 10:09:13
categories: ["Node.js"]
---

`exports` 变量是在模块的文件级别作用域内有效的，它在**模块被执行前**被赋予 `module.exports`。

<!-- more -->

我们通过一个依赖循环的例子来理解 `exports` 和 `module.exports` 的区别。

## 依赖循环

如下面官网的例子:

文件 `a.js`:

```javascript
console.log('a 开始');
exports.done = false;
const b = require('./b.js');
console.log('在 a 中，b.done = %j', b.done);
exports.done = true;
console.log('a 结束');
```

文件 `b.js`:

```javascript
console.log('b 开始');
exports.done = false;
const a = require('./a.js');
console.log('在 b 中，a.done = %j', a.done);
exports.done = true;
console.log('b 结束');
```

`main.js`：

```javascript
console.log('main 开始');
const a = require('./a.js');
const b = require('./b.js');
console.log('在 main 中，a.done=%j，b.done=%j', a.done, b.done);
```

运行结果：

```bash
main 开始
a 开始
b 开始
在 b 中，a.done = false
b 结束
在 a 中，b.done = true
a 结束
在 main 中，a.done=true，b.done=true
```

当 `main.js` 加载 `a.js` 时，`a.js` 又加载 `b.js`。 此时，`b.js` 会尝试去加载 `a.js`。 为了防止无限的循环，会返回一个`a.js`
的 `exports` 对象的 `未完成的副本`(`{done: false}`) 给 `b.js` 模块。

然后 `b.js` 完成加载，并将 `exports` 对象提供给 `a.js` 模块。当 `main.js` 加载这两个模块时，它们都已经完成加载。所以输
出：`在 main 中，a.done=true，b.done=true`。

## exports 和 module.exports 的区别

- `exports` 是 `module.exports` 的引用
- `module.exports` 初始值为一个空对象 `{}`，所以 `exports` 初始值也是 `{}`
- `require()` 返回的是 `module.exports` 而不是 `exports`

`module.exports.foo = ...` 可以写成 `exports.foo = ...`。 注意，**如果一个新的 objetc 被赋值给 `exports`，它就不再绑定
到 `module.exports`**：

```javascript
module.exports.done = true; // 从对模块的引用中导出
exports = { done: false };  // 不导出，只在模块内有效
```

当 `module.exports` 属性被一个新的对象完全替代时，也会重新赋值 `exports`，例如：

```javascript
module.exports = exports = function hello() {
  //TODO
};
```

把依赖循环的例子中的 `a.js` 稍作修改如下:

```javascript
console.log('a 开始');
module.exports = {
  done: false
};
const b = require('./b.js');
console.log('在 a 中，b.done = %j', b.done);
exports.done = true;
console.log('a 结束');
```

运行结果：

```bash
main 开始
a 开始
b 开始
在 b 中，a.done = false
b 结束
在 a 中，b.done = true
a 结束
在 main 中，a.done=false，b.done=true
```

所以说 `require()` 返回的是 `module.exports` 而不是 `exports`。

再修改文件 `a.js` 如下:

```javascript
console.log('a 开始');
const b = require('./b.js');
console.log('在 a 中，b.done = %j', b.done);
exports.done = true;
console.log('a 结束');
```

运行结果：

```bash
main 开始
a 开始
b 开始
在 b 中，a.done = undefined
b 结束
在 a 中，b.done = true
a 结束
在 main 中，a.done=true，b.done=true
```

我们看到 `在 b 中，a.done = undefined`，这是因为 `b.js` 尝试加载 `a.js` 时，这是 `a.js` 的 `module.exports` 对象是 `{}`。

## require 方法的的实现

通过下面 `require()` 方法实现的伪代码，更容易理解：

``` javascript
function require(/* ... */) {
  const module = { exports: {} };
  ((module, exports) => {
    // 模块代码在这。在这个例子中，定义了一个函数。
    function someFunc() {}
    exports = someFunc;
    // 此时，exports 不再是一个 module.exports 的快捷方式，
    // 且这个模块依然导出一个空的默认对象。
    module.exports = someFunc;
    // 此时，该模块导出 someFunc，而不是默认对象。
  })(module, module.exports);
  return module.exports;
}
```

**参考文章** [Node.js 中文文档](http://Node.js.cn/api/modules.html)
