---
title: JavaScript的闭包
date: 2017-09-19 23:26:21
categories: ["Javascript"]
tags: []
---
JavaScript的闭包有两个用途：
1. 访问函数内部的变量.
2. 让变量的值在作用域内保持不变。

<!-- more -->
JavaScript没有块作用域（循环内部，if内部），函数是JavaScript 中唯一有作用域的对象，下面结合两则示例对JavaScript的闭包做简单说明。
### JavaScript中使用闭包的陷阱
如果在循环中创建函数，并引用循环变量，原意是打印出0，1，2，但结果却是一样的:
``` javascript
var tasks = [];
for (var i=0; i<3; i++) {
    tasks.push(function() { console.log('>>> ' + i); });
}
console.log('end for.');
for (var j=0; j<tasks.length; j++) {
    tasks[j]();
}

//end for.
//>>> 3>>> 3>>> 3
```
问题的原因在于，函数创建时并未执行，所以先打印end for.，然后才执行函数。
由于函数引用了循环变量i，在函数执行时，由于i的值已经变成了3，所以，打印出的结果不对。
注意到i为什么不是2，因为i++ 多加一次。
[解决方法](#jump)
### 闭包的使用
#### <span id="jump">保持变量的作用域</span>
> ES6中可以使用let定义块级变量

``` javascript
var tasks = [];

for(var i = 0; i < 10; i++) {
    (function(e) {
        setTimeout(function() {
            console.log(e);
        }, 1000);
    })(i);
}
```
function()匿名函数立即被执行，因此，闭包拿到的参数n就是当前循环变量的值的副本。为变量构建一个作用域。

### 访问函数内部的变量
在JavaScript中，函数可以访问其外部定义的变量，外部不能访问函数内部定义的变量。而通过调用闭包函数达到访问函数内部变量的目的。
在下面示例中，count相当于一个“私有变量”，在Counter函数外部不能访问这个变量。在Counter中，还定义了increment 和 get两个“闭包函数”，
这两个函数都保持着对Counter作用域的引用，因此可以访问到Counter作用域内定义的变量count。

``` javascript
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

1. 由于闭包会使得函数中的变量都被保存在内存中，内存消耗很大，所以不能滥用闭包，否则会造成性能问题，可能导致内存泄露。
解决方法是，在退出函数之前，将不使用的局部变量全部删除。一旦数据不再有用，最好通过将其值设置为null来释放其引用——这个做法叫做解除引用（dereferencing）。

2. 闭包会在父函数外部，改变父函数内部变量的值。所以，如果你把父函数当作对象使用，把闭包当作它的公用方法，
把内部变量当作它的私有属性，这时一定要小心，不要随便改变父函数内部变量的值。

3. 在闭包中使用this对象也可能会导致一些问题。我们知道，this对象是在运行时基于函数的执行环境绑定的：
在全局函数中，this等于window，而当函数被作为某个对象的方法调用时，this等于那个对象。不过，匿名函数的执行环境具有全局性，因此其this对象通常指向window，
不过，把外部作用域中的this对象保存在一个闭包能够访问到的变量里，就可以让闭包访问该对象了。
