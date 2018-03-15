---
title: JavaScript中的apply、call、bind方法
date: 2017-09-20 19:54:43
categories: ["Javascript"]
---

`apply`、`call`、`bind`方法都有改变函数的`this`的作用域,实际上等于设置函数体内的`this`对象的值。

<!-- more -->

### apply
`apply`方法有两个参数，第一个参数为`this`所要指向的那个对象，第二个参数是一个数组，绑定对象的参数数组。apply()的参数为空时，默认调用全局对象。
``` javascript
function add (x, y) {
    console.log(x + y);
}

function multiply (x, y){
    add.apply(this, [x, y]); //绑定参数组
}

function sub (x, y){
    add.apply(this, arguments); //绑定arguments对象
}
multiply(2, 3);  //5
sub(2, 3);  //5
```
> 绑定arguments对象和绑定参数组在使用上没有区别，前者更常用。

### call
`call`方法与`apply`方法作用相同，在参接上有所区别。第一个参数同样是`this`所要指向的那个对象，但是其余参数都是直接传递给函数。

``` javascript
function add (x, y, z) {
    console.log(x + y + z);
}

function multiply (x, y, z){
    add.call(this, x, y, z); //绑定参数列表
}

multiply(2, 3, 4);  //9

```

### bind

* `bind`创建一个函数实例，参数传递形式与`call`方法相同。如果`bind`方法的第一个参数是`null`或`undefined`，等于将`this`绑定到全局对象，函数运行时`this`指向全局对象。

``` javascript
window.color = 'green';
var obj = {color:'red'};
function showColor (){
    console.log(this.color);
}

showColor.call(window);    //green
var objShowColor = showColor.bind(obj);
objShowColor();    //red
```

objShowColor方法是通过`bind`方法创建的`showColor`函数的实例方法，其`this`作用域为`obj`对象，因此，实列调用后输出值是“red”。

`bind`方法有一些使用注意点。

**（1）每一次返回一个新函数**

`bind`方法每运行一次，就返回一个新函数，这会产生一些问题。比如，监听事件的时候，不能写成下面这样。

```javascript
element.addEventListener('click', o.m.bind(o));
```

上面代码中，`click`事件绑定`bind`方法生成的一个匿名函数。这样会导致无法取消绑定，所以，下面的代码是无效的。

```javascript
element.addEventListener('click', o.m.bind(o)); //o.m.bind(o) `bind`方法生成的一个匿名函数

element.removeEventListener('click', o.m.bind(o)); //这里的o.m.bind(o) 是`bind`方法生成另一个新的匿名函数，所以removeEventListener不能取消绑定。
```

正确的方法是写成下面这样：

```javascript
var listener = o.m.bind(o);
element.addEventListener('click', listener);
//  ...
element.removeEventListener('click', listener);
```

**（2）结合回调函数使用**

回调函数是 JavaScript 最常用的模式之一，但是一个常见的错误是，将包含`this`的方法直接当作回调函数。解决方法就是使用`bind`方法，将`counter.inc`绑定`counter`。

```javascript
var counter = {
  count: 0,
  inc: function () {
    'use strict';
    this.count++;
  }
};

function callIt(callback) {
  callback();
}

callIt(counter.inc.bind(counter));
counter.count // 1
```

上面代码中，`callIt`方法会调用回调函数。这时如果直接把`counter.inc`传入，调用时`counter.inc`内部的`this`就会指向全局对象。

使用`bind`方法将`counter.inc`绑定`counter`以后，就不会有这个问题，`this`总是指向`counter`。

还有一种情况比较隐蔽，就是某些数组方法可以接受一个函数当作参数。这些函数内部的`this`指向，很可能也会出错。

```javascript
var obj = {
  name: '张三',
  times: [1, 2, 3],
  print: function () {
    this.times.forEach(function (n) {
      console.log(this.name);
    });
  }
};

obj.print()
// 没有任何输出
```

上面代码中，`obj.print`内部`this.times`的`this`是指向`obj`的，这个没有问题。但是，`forEach`方法的回调函数内部的`this.name`却是指向全局对象，

导致没有办法取到值。稍微改动一下，就可以看得更清楚。

```javascript
obj.print = function () {
  this.times.forEach(function (n) {
    console.log(this === window);
  });
};

obj.print()
// true
// true
// true
```

解决这个问题，也是通过`bind`方法绑定`this`。

```javascript
obj.print = function () {
  this.times.forEach(function (n) {
    console.log(this.name);
  }.bind(this));
};

obj.print()
// 张三
// 张三
// 张三
```

**（3）结合`call`方法使用**

利用`bind`方法，可以改写一些 JavaScript 原生方法的使用形式，以数组的`slice`方法为例。

```javascript
[1, 2, 3].slice(0, 1) // [1]
// 等同于
Array.prototype.slice.call([1, 2, 3], 0, 1) // [1]
```

上面的代码中，数组的`slice`方法从`[1, 2, 3]`里面，按照指定位置和长度切分出另一个数组。这样做的本质是在`[1, 2, 3]`上面调用`Array.prototype.slice`方法，

因此可以用`call`方法表达这个过程，得到同样的结果。

`call`方法实质上是调用`Function.prototype.call`方法，因此上面的表达式可以用`bind`方法改写。

```javascript
var slice = Function.prototype.call.bind(Array.prototype.slice);
slice([1, 2, 3], 0, 1) // [1]
```

上面代码的含义就是，将`Array.prototype.slice`变成`Function.prototype.call`方法所在的对象，调用时就变成了`Array.prototype.slice.call`。

类似的写法还可以用于其他数组方法。

```javascript
var push = Function.prototype.call.bind(Array.prototype.push);
var pop = Function.prototype.call.bind(Array.prototype.pop);

var a = [1 ,2 ,3];
push(a, 4)
a // [1, 2, 3, 4]

pop(a)
a // [1, 2, 3]
```

如果再进一步，将`Function.prototype.call`方法绑定到`Function.prototype.bind`对象，就意味着`bind`的调用形式也可以被改写。

```javascript
function f() {
  console.log(this.v);
}

var o = { v: 123 };
var bind = Function.prototype.call.bind(Function.prototype.bind);
bind(f, o)() // 123
```

上面代码的含义就是，将`Function.prototype.bind`方法绑定在`Function.prototype.call`上面，所以`bind`方法就可以直接使用，不需要在函数实例上使用。


### 比较
`call`和`apply`两个方法在作用上没有任何区别，不同的只是二者的参数的传递方式。至于使用哪一个方法，取决于你的需要，如果打算直接传入`argumnets`对象或应用的函数接收到的也是数组，
那么使用`apply`方法比较方变，其它情况使用`call`则相对方便一些。
`bind`方法会在指定对象的作用上创建一个函数实例，而call和apply方法是在指定对象的作用上运行函数。
> bind方法会创建函数实例，所以需要运行实例后才会发生调用。而call和apply则会指定作用域上直接调用函数，不需要运行。
