---
title: Javascript深入学习（二）
date: 2018-02-27 17:14:21
categories: ["Javascript"]
tags: ["Javascript深入学习系列"]
---

在Javascript深入学习（一）中，主要学习记录js的基础知识，本章学习js的变量作用域，内存问题，和引用类型。

<!-- more -->

## 变量，作用域，内存

ECMAScript变量包含两种不同数据类型的值：基本类型值和引用类型值。
基本数据类型：Undefined、Null、Boolean、Number和String。
引用类型的值是保存在内存中的对象。JavaScript不允许直接访问内存中的位置，也就是说不能直接操作对象的内存空间。在操作对象时，实际上是在操作对象的引用而不是实际的对象。

> 只能给引用类型值动态地添加属性
> 当从一个变量向另一个变量复制引用类型的值时，同样也会将存储在变量对象中的值复制一份放到为新变量分配的空间中。
不同的是，这个值的副本实际上是一个指针，而这个指针指向存储在堆中的一个对象。
> ECMAScript中所有函数的参数都是按值传递的。也就是说，把函数外部的值复制给函数内部的参数，就和把值从一个变量复制到另一个变量一样。
基本类型值的传递如同基本类型变量的复制一样，而引用类型值的传递，则如同引用类型变量的复制一样。

### 执行环境及作用域
JavaScript没有块级作用。
执行环境有全局执行环境（也称为全局环境）和函数执行环境之分，每次进入一个新执行环境，都会创建一个用于搜索变量和函数的作用域链，
函数的局部环境不仅有权访问函数作用域中的变量，而且有权访问其包含（父）环境，乃至全局环境，全局环境只能访问在全局环境中定义的变量和函数，而不能直接访问局部环境中的任何数据。

### 垃圾收集

JavaScript具有自动垃圾收集机制。
JavaScript中最常用的垃圾收集方式是标记清除（mark-and-sweep）。当变量进入环境（例如，在函数中声明一个变量）时，就将这个变量标记为“进入环境”。
而当变量离开环境时，则将其标记为“离开环境”。垃圾收集器在运行的时候会给存储在内存中的所有变量都加上标记（当然，可以使用任何标记方式）。然后，
它会去掉环境中的变量以及被环境中的变量引用的变量的标记。而在此之后再被加上标记的变量将被视为准备删除的变量，
原因是环境中的变量已经无法访问到这些变量了。最后，垃圾收集器完成内存清除工作，销毁那些带标记的值并回收它们所占用的内存空间。

另一种不太常见的垃圾收集策略叫做引用计数（reference counting）。当代码中存在循环引用现象时，“引用计数”算法就会导致问题。

## 引用类型
确定一个值是哪种基本类型可以使用typeof操作符，而确定一个值是哪种引用类型可以使用instanceof操作符。

### Array类型

#### 检测数组
``` javascript
if (value instanceof Array){}

if (Array.isArray(value)){}
```

#### 转换
所有对象都具有toLocaleString()、toString()和valueOf()方法。
``` javascript
var colors = ["red", "blue", "green"];
console.log(colors.toString()); // red,blue,green
console.log(colors.valueOf()); // [ 'red', 'blue', 'green' ]
```

toString()方法会返回由数组中每个值的字符串形式拼接而成的一个以逗号分隔的字符串。而调用valueOf()返回的还是数组。

#### 方法
push(): 接收任意数量的参数，把它们逐个添加到数组末尾，并返回修改后数组的长度。
pop(): 从数组末尾移除最后一项，减少数组的length值，然后返回移除的项。
shift()： 移除数组中的第一个项并返回该项，同时将数组长度减1。
unshift()： unshift()与shift()的用途相反，在数组前端添加任意个项并返回新数组的长度。

### function类型
在函数内部，有两个特殊的对象：arguments和this。其中，arguments是一个类数组对象，包含着传入函数中的所有参数。
this指向调用它的对象。
虽然arguments的主要用途是保存函数参数，
但这个对象还有一个名叫callee的属性，该属性是一个指针，指向拥有这个arguments对象的函数。请看下面这个非常经典的阶乘函数。

``` javascript
function factorial(num){
    if (num <=1) {
        return 1;
    } else {
        return num * factorial(num-1) //递归, 但问题是这个函数的执行与函数名factorial紧紧耦合在了一起
    }
}


function factorial(num){
    if (num <=1) {
        return 1;
    } else {
        return num * arguments.callee(num-1)
    }
}
```

ECMAScript 5也规范化了另一个函数对象的属性：caller，这个属性中保存着调用当前函数的函数的引用，如果是在全局作用域中调用当前函数，它的值为null。

``` javascript
function outer(){
    inner();
}

function inner(){
    alert(inner.caller);
}

outer();
```
inner.caller就指向outer()，也可以通过arguments.callee.caller来访问相同的信息。


#### 函数属性和方法
每个函数都包含两个属性：length和prototype。length属性表示函数希望接收的命名参数的个数。
prototype是保存它们所有实例方法的真正所在。如toString()和valueOf()等方法实际上都保存在prototype。

每个函数都包含两个非继承而来的方法：apply()和call()。这两个方法的用途都是在特定的作用域中调用函数，实际上等于设置函数体内this对象的值。
ECMAScript 5还定义了一个方法：bind()。这个方法会创建一个函数的实例，其this值会被绑定到传给bind()函数的值。

``` javascript
var color = "red";
var o = { color: "blue" };
function sayColor(){
    console.log(this.color);
}
var objectSayColor = sayColor.bind(o);
objectSayColor(); //blue
```
sayColor()调用bind()并传入对象o，创建了objectSayColor()函数。this指向o，所以输出“blue”。