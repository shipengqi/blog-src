---
title: JavaScript 中的 apply、call、bind 方法
date: 2017-05-20 19:54:43
categories: ["Javascript"]
---

JavaScript 中的 `apply`、`call`、`bind` 方法都可以改变函数的 `this` 的作用域。

<!--more-->

## apply

`apply` 方法有两个参数，第一个参数为 `this` 所要指向的那个对象，第二个参数是一个数组，绑定对象的参数数组。`apply()`的参数为空时，默认是指向
全局对象。

```javascript
function add (x, y) {
    console.log(x + y);
}

function multiply (x, y){
    add.apply(this, [x, y]); // 绑定参数组
}

function sub (x, y){
    add.apply(this, arguments); // 绑定 arguments 对象
}

multiply(2, 3);  // 5
sub(2, 3);  // 5
```

> 绑定 arguments 对象和绑定参数组在使用上没有区别。

## call

`call` 方法与 `apply` 方法作用相同，在参接上有所区别。第一个参数同样是 `this` 所要指向的那个对象，但是其余参数都是直接传递给函数。

```javascript
function add (x, y, z) {
    console.log(x + y + z);
}

function multiply (x, y, z){
    add.call(this, x, y, z); // 绑定参数列表
}

multiply(2, 3, 4);  // 9

```

## bind

`bind` 方法会创建一个函数实例，参数传递形式与 `call` 方法相同。如果 `bind` 方法的第一个参数是 `null` 或 `undefined`，等于将 `this` 绑定到全局
对象，函数运行时 `this` 指向全局对象。

```javascript
window.color = 'green';
var obj = {color:'red'};
function showColor (){
    console.log(this.color);
}

showColor.call(window);    // green
var objShowColor = showColor.bind(obj);
objShowColor();    // red
```

`objShowColor` 方法是通过 `bind` 方法创建的 `showColor` 函数的实例方法，其 `this` 作用域为 `obj` 对象，因此，实列调用后输出值是 “red”。

`bind` 方法有一些使用注意点。

1. 每一次返回一个新函数

`bind` 方法每运行一次，就返回一个新函数，这会产生一些问题。比如，监听事件的时候，不能写成下面这样。

```javascript
element.addEventListener('click', o.m.bind(o));
```

上面代码中，`click` 事件绑定了 `bind` 方法生成的一个匿名函数。这样会导致无法取消绑定，所以，下面的代码是无效的。

```javascript
element.addEventListener('click', o.m.bind(o)); // o.m.bind(o) bind 方法生成的一个匿名函数

element.removeEventListener('click', o.m.bind(o)); // 这里的 o.m.bind(o) 是 bind 方法生成另一个新的匿名函数，所以 removeEventListener 不能取消绑定。
```

正确的方法是写成下面这样：

```javascript
var listener = o.m.bind(o);
element.addEventListener('click', listener);
//  ...
element.removeEventListener('click', listener);
```

2. 结合回调函数使用

回调函数是 JavaScript 最常用的模式之一，但是一个常见的错误是，将包含 `this` 的方法直接当作回调函数，如下面的例子：

```javascript
var counter = {
  count: 0,
  inc: function () {
    'use strict';
    this.count ++;
  }
};

function callIt(callback) {
  callback();
}

callIt(counter.inc.bind(counter));
console.log(counter.count) // 1
```

上面代码中，`callIt` 方法会调用回调函数。这时如果直接把 `counter.inc` 传入，调用时 `counter.inc` 内部的 `this` 就会指向全局对象。

使用 `bind` 方法将 `counter.inc` 绑定 `counter` 以后，就不会有这个问题，`this` 指向了 `counter`。

### 比较

- `call` 和 `apply` 两个方法在作用上没有任何区别，不同的只是二者的参数的传递方式。至于使用哪一个方法，取决于你的需要，如果打算直接
传入 `argumnets` 对象或应用的函数接收到的也是数组，那么使用 `apply` 方法比较方便，其它情况使用 `call` 则相对方便一些。
- `bind` 方法会在指定对象的作用上创建一个函数实例，而 `call` 和 `apply` 方法是在指定对象的作用上运行函数。
- `bind` 方法会创建函数实例，所以需要运行实例后才会发生调用。而 `call` 和 `apply` 则会指定作用域上直接调用函数，不需要再次运行。
