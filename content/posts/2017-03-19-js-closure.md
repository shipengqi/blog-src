---
title: JavaScript 的闭包
date: 2017-03-19 23:26:21
categories: ["Javascript"]
---
JavaScript 的闭包有两个用途：

1. 访问函数内部的变量。
2. 让变量的值在作用域内保持不变。


JavaScript 没有块作用域（比如 `for` 循环，`if` 的 `{}` 中的代码块），函数是 JavaScript 中唯一有作用域的对象。

## JavaScript 中使用闭包的陷阱

如果在循环中创建函数，并引用循环变量，原意是打印出 `0`，`1`，`2`，但结果却是一样的:

```javascript
var tasks = [];
for (var i = 0; i < 3; i ++) {
    tasks.push(function() { console.log('>>> ' + i); });
}
console.log('end for.');
for (var j = 0; j < tasks.length; j ++) {
    tasks[j]();
}

// end for.
// >>> 3>>> 3>>> 3
```

问题的原因在于，函数创建时并未执行，所以先打印 `end for`，然后才执行函数。
由于函数引用了循环变量 `i`，在函数执行时，由于 `i` 的值已经变成了 `3`，所以，打印出的结果不对。
注意到 `i` 为什么不是 `2`，因为 `i++` 多加一次。

解决方法可以使用[闭包](#jump)

## 闭包的使用

### <span id="jump">保持变量的作用域</span>

> ES6中可以使用 `let` 定义块级变量

```javascript
for(var i = 0; i < 10; i++) {
    (function(e) {
        setTimeout(function() {
            console.log(e);
        }, 1000);
    })(i);
}
```

`function()` 匿名函数立即被执行，因此，闭包拿到的参数 `i` 就是当前循环变量的值的副本。为变量构建一个作用域。

### 访问函数内部的变量

在 JavaScript 中，函数可以访问其外部定义的变量，外部不能访问函数内部定义的变量。而通过调用闭包函数达到访问函数内部变量的目的。
在下面示例中，`count` 相当于一个“私有变量”，在 `Counter` 函数外部不能访问这个变量。在 `Counter` 中，还定义了 `increment` 和 `get` 两
个“闭包函数”，这两个函数都保持着对 `Counter` 作用域的引用，因此可以访问到 `Counter` 作用域内定义的变量 `count`。

```javascript
function Counter() {
 var count = 2;
 return {
    increment: function() { count++; },
    get: function() { return count; }
 }
}
var foo = new Counter();
foo.increment();
foo.get(); // -> 3
```

### 闭包的注意点

1. 由于闭包会使得函数中的变量都被保存在内存中，所以不能滥用闭包，否则可能导致内存泄露。解决方法是，在退出函数之前，将不使用的局部变量全部删除。一
旦数据不再有用，最好通过将其值设置为 `null` 来释放其引用——这个做法叫做解除引用（`dereferencing`）。

2. 闭包会在父函数外部，改变父函数内部变量的值。所以，如果你把父函数当作对象使用，把闭包当作它的公用方法，把内部变量当作它的私有属性，这时一定要小
心，不要随便改变父函数内部变量的值。

3. 在闭包中使用 `this` 对象也可能会导致一些问题。`this` 对象是在运行时基于函数的执行环境绑定的：
在全局函数中，`this` 等于 `window`，而当函数被作为某个对象的方法调用时，`this` 等于那个对象。不过，匿名函数的执行环境具有全局性，因此
其 `this` 对象通常指向 `window`，不过，把外部作用域中的 `this` 对象保存在一个闭包能够访问到的变量里，就可以让闭包访问该对象了。
