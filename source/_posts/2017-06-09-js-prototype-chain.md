---
title: Javascript 原型链
date: 2017-06-09 22:21:23
categories: ["Javascript"]
---

每一个 Javascript 对象(null 除外)都和另一个对象相关联，即原型，每一个对象都从原型继承属性。

<!-- more -->

## 原型链

```javascript
function Test(value) {
  this.a = value;
}
Test.prototype.getValue = function() {
  console.log(this.a);
};
var test = new Test(1);
test.getValue(); // 输出1
```

Javascript 在创建对象的时候，都有一个叫做 `__proto__` 的内置属性，用于指向创建它的函数对象的原型对象 `prototype`。上面的代码中：

```javascript
console.log(test.__proto__ === Test.prototype) //true
```

同样，`Test.prototype` 对象也有 `__proto__` 属性，它指向创建它的函数对象（Object）的 `prototype`

```javascript
console.log(Test.prototype.__proto__ === Object.prototype) // true
```

继续，`Object.prototype` 对象也有 `__proto__` 属性，但它比较特殊，为 `null`

```javascript
console.log(Object.prototype.__proto__) //null
```

这个由 `__proto__` 串起来的直到 `Object.prototype.__proto__` 为 `null` 的链叫做**原型链**。

## prototype 和 __proto__

`prototype` 是函数的一个属性（每个函数都有一个 `prototype` 属性），这个属性是一个指针，指向一个对象。

`prototype` 包含了 2 个属性，

- `constructor`，值为函数本身
- `__proto__`，值为父函数的 `prototype` 属性值。

可以通过 `hasOwnProperty` 方法验证。

**`prototype` 是函数的内置属性，`__proto__` 是对象的内置属性**。

## new 的过程

```javascript
function Test() {}

var t = new Test();
```

new 的过程拆分成以下三步：

1. `var t = {};` 初始化一个对象 `t`
2. `t.__proto__ = Test.prototype;`
3. `Test.call(t);`
