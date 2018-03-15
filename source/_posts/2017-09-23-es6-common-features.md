---
title: 常用ES6特性概览
date: 2017-09-23 18:42:26
categories: ["Javascript"]
tags: ["ES6"]
---
ES6新的JavaScript语言的标准，目前它已经广泛用于编程实践中。
下面是最常用的ES6特性：
- let和const
- 字符串模板
- 箭头函数
- 解构赋值
- for of
- 类
- 参数默认值，不定参数，拓展参数
- 模块
- Promises

<!-- more -->

## let和const

var定义的变量未函数级作用域，let定义的变量为块级作用域，const与let一样，也是块级作用域, 但是声明的是常量。
一旦声明，常量的值就不能改变:
``` javascript
const a = 666

a = 888 //SyntaxError: "a" is read-only
```
> const有一个很好的应用场景，就是当我们引用第三方库的时声明的变量: 
`const express = require('express')`

var和let const的区别：

### 块级作用域
ES5 只有全局作用域和函数作用域，没有块级作用域，这带来很多不合理的场景。

1. 内层变量覆盖外层变量。
``` javascript
var name = 'xiaoming'

if (true) {
    var name = 'daming'
    console.log(name)  //daming
}

console.log(name)  //daming

//使用`var` 两次输出都是daming。

let name = 'xiaoming'

if (true) {
    let name = 'daming'
    console.log(name)  //daming
}

console.log(name)  //xiaoming
```
2. 用来计数的循环变量泄露为全局变量
``` javascript
//使用var

var tasks = [];
for (var i = 0; i < 3; i ++) {
    tasks.push(function() { console.log('>>> num: ' + i); });
}

for (var j = 0; j < tasks.length; j ++) {
    tasks[j]();
}

//输出结果
//>>> num: 3 
//>>> num: 3 
//>>> num: 3

//使用let

var tasks = [];
for (let i = 0; i < 3; i ++) {
    tasks.push(function() { console.log('>>> num: ' + i); });
}

for (var j = 0; j < tasks.length; j ++) {
    tasks[j]();
}

//输出结果
//>>> num: 0 
//>>> num: 1 
//>>> num: 2
```

使用let，就省去了使用闭包解决这个问题。

### 代码块内有效

let const只在代码块内有效:
``` javascript
{
  let a = 10;
  var b = 1;
}

a // ReferenceError: a is not defined.
b // 1
```

### 不允许重复声明

let const不允许重复声明:

``` javascript
{
  let a = 1;
  var a = 2; // error
}


{
  let a = 1;
  let a = 2; // error
}
```

## 字符串模板

模板字符串（template string）是增强版的字符串，用反引号（`）标识。
``` javascript
// 普通字符串
`General template string`

// 多行字符串
`MultiLine
 template string.`

console.log(`MultiLine
 template string.`);

// 字符串中嵌入变量
var name = "xiaoming";
`Hello ${name}`
```

> 模板字符串之中还能调用函数。
``` javascript
`foo ${fn()} bar`
```

## 箭头函数
箭头函数内部的this是词法作用域，由上下文确定，简单说箭头函数内部有绑定this的机制，用它来写function比原来的写法要简洁清晰很多。
``` javascript
function(i){ return i + 1; } //ES5
(i) => i + 1 //ES6
(i) => { //ES6
	return i + 1 
}
```

绑定this:
由于this在箭头函数中已经按照词法作用域绑定了，所以，用call()或者apply()调用箭头函数时，无法对this进行绑定，即传入的第一个参数被忽略。
箭头函数可以让setTimeout里面的this，绑定定义时所在的作用域，而不是指向运行时所在的作用域。实际原因是箭头函数没有自己的this，它的this是继承外面的，因此内部的this就是外层代码块的this。所以也就不能用`call`、`apply`、`bind`这些方法去改变this的指向。除了this，以下三个变量在箭头函数之中也是不存在的，指向外层函数的对应变量：arguments、super、new.target。
``` javascript
//ES5
function _LazyMan(_name) {
    var _this = this; // push函数里面的this和setTimeout函数里面的this应该指向全局作用域，所以要缓存当前this指向，
                      //如果是箭头函数则不需要缓存this
    _this.tasks = [];
    _this.tasks.push(function() {
        console.log('Hi! This is ' + _name + '!');
        _this.next();
    });

    //通过settimeout的方法，将执行函数放入下一个事件队列中，从而达到先注册事件，后执行的目的
    setTimeout(function() {
        _this.next();
    }, 0);

    //或者
	/*setTimeout(function(){
	           this.next();
	       }.bind(this), 0)*/
}



//ES6
class _LazyMan {
    constructor ( name ) {
        this.tasks = [];
        let task = (name => () => {
            console.log ( `Hi! This is ${name} !` );
            this.next ();
        }) ( name );
        this.tasks.push ( task );

        setTimeout ( () => {
            this.next ();
        }, 0 );

    }
}
```
## 解构赋值
ES6允许按照一定模式，从数组和对象中提取值，对变量进行赋值，这被称为解构（Destructuring）。
``` javascript
//ES5
let cat = 'ken'
let dog = 'lili'
let zoo = {cat: cat, dog: dog}
console.log(zoo)  //Object {cat: "ken", dog: "lili"}

//ES6
//反过来写
```
## for of
for...of循环可以使用的范围包括数组、Set 和 Map 结构、类似数组的对象(`arguments`)、Generator、String。
for...of循环可以代替数组实例的forEach方法。for...of循环读取键值。
``` javascript
arr = [a, b, c]
for(let v of arr) {
  console.log(v); // a, b, c
}
```
## 类
ES6 提供了更接近传统语言的写法，引入了 Class（类）这个概念，作为对象的模板。通过class关键字，可以定义类。

### 基本用法
``` javascript
//ES5
function Student(x, y) {
  this.name = x;
  this.age = y;
}

Student.prototype.sayHello = function () {
  return 'hello !' + this.name;
};

var student = new Student('xiaoming', 18);

//ES6
//定义类
class Student {
  constructor(x, y) {
	this.name = x;
	this.age = y;
  }

  sayHello() {
    return `hello ! #{this.name}`;
  }

    // 私有方法
  _getAge(baz) {
    return this.age;
  }
}

//私有方法
function getAge(baz) {
  return this.age;
}

```
`constructor`方法是类的默认方法，通过new命令生成对象实例时，自动调用该方法。一个类必须有constructor方法，如果没有显式定义，一个空的constructor方法会被默认添加。
ES6不提供私有方法，只能通过变通方法实现。一种做法通常是在命名上加`_`, 如上面的例子`_getAge`,
另一种方法就是在类的外部的定义方法方法都是对外可见的。

还有一种方法是利用Symbol值的唯一性，将私有方法的名字命名为一个Symbol值。
`` javascript
const bar = Symbol('bar');
const snaf = Symbol('snaf');

class Student {
  constructor(x) {
	this.name = x;
	this.age = 19;
  }

  // 公有方法
  foo(baz) {
    this[bar](baz);
  }

  // 私有方法
  [bar](baz) {
    return this[snaf] = baz;
  }
}
```
上面代码中，bar和snaf都是Symbol值，导致第三方无法获取到它们，因此达到了私有方法和私有属性的效果。

#### 私有属性

ES6 不支持私有属性，目前，有一个提案，为class加了私有属性。方法是在属性名之前，使用`#`表示。
之所以要引入一个新的前缀#表示私有属性，而没有采用`private`关键字，是因为 `JavaScript` 是一门动态语言，
使用独立的符号似乎是唯一的可靠方法，能够准确地区分一种属性是否为私有属性。另外，`Ruby` 语言使用`@`表示私有属性，
`ES6` 没有用这个符号而使用#，是因为`@`已经被留给了 `Decorator`。它也可以用来写私有方法。

``` javascript
class Point {
  #x;
  #a;
  #b;
  #sum() { return #a + #b; } //私有方法
  constructor(x = 0) {
    #x = +x; // 写成 this.#x 亦可
  }

  get x() { return #x }
  set x(value) { #x = +value }
}
```
上面代码中，`#x`就表示私有属性`x`，在`Point`类之外是读取不到这个属性的。还可以看到，私有属性与实例的属性是可以同名的（比如，`#x`与`get x()`）。
### Class 的静态方法

如果在一个方法前，加上`static`关键字，就表示该方法不会被实例继承，而是直接通过类来调用，这就称为“静态方法”。
``` javascript
class Student {
  constructor(x) {
	this.name = x;
	this.age = 19;
  }

  sayHello() {
    return `hello ! #{this.name}`;
  }

    // 静态方法
  static getAge(baz) {
    return this.age;
  }
}

Student.getAge() // '19'
```

上面代码中，Student 类的 getAge 方法是一个静态方法，可以这样调用`Student.getAge()`。如果在实例上调用静态方法，会抛出一个错误，表示不存在该方法。

> 如果静态方法包含`this`关键字，这个`this指`的是类，而不是实例。
> 静态方法可以与非静态方法重名。
> 类不存在变量提升,必须先定义,后使用



``` javascript
//父类的静态方法，可以被子类继承。
class Foo {
  static classMethod() {
    return 'hello';
  }
}

class Bar extends Foo {
}

Bar.classMethod() // 'hello'


//静态方法也是可以从super对象上调用的。
class Foo {
  static classMethod() {
    return 'hello';
  }
}

class Bar extends Foo {
  static classMethod() {
    return super.classMethod() + ', too';
  }
}

Bar.classMethod() // "hello, too"
```

### Class 的静态属性
静态属性指的是 `Class` 本身的属性，即`Class.propName`，而不是定义在实例对象`this`上的属性。
``` javascript
class Foo {
}

Foo.prop = 1;
Foo.prop // 1
```

上面的代码中为Foo类定义了一个静态属性prop。

### new.target

ES6 为`new`命令引入了一个`new.target`属性，该属性一般用在构造函数之中，
返回`new`命令作用于的那个构造函数。如果构造函数不是通过new命令调用的，`new.target`会返回`undefined`。

``` javascript
function Test(str) {
  if (new.target !== undefined) {
    console.log(new.target);
  } else {
    throw new Error('Class constructor cannot be invoked without new');
  }
}

var test = new Test('hello'); //[Function: Test]
Test.call(test, 'world');  //Error: Class constructor cannot be invoked without new
```

Class 内部调用new.target，返回当前 Class。
子类继承父类时，new.target会返回子类。

利用这个特点，可以写出不能独立使用、必须继承后才能使用的类。
``` javascript
class Test {
  constructor() {
    if (new.target === Test) {
      throw new Error('本类不能实例化');
    }
  }
}

class Test2 extends Test {
  constructor() {
    super();
    console.log(new.target)
    // ...
  }
}

var x = new Test();  // Error: 本类不能实例化
var y = new Test2();  // [Function: Test2]
```
### 继承

``` javascript
class Student {
  constructor(x, y) {
	this.name = x;
	this.age = y;
  }

  getName() {
    return this.name;
  }

  getAge(baz) {
    return this.age;
  }
}

class Pupils extends Student {
    constructor(){
        super()
        this.type = 'pupils'
    }

    getInfo() { 
        return super.getName() + ' ' + super.getAge(); // 
    }
}
```
Class 可以通过extends关键字实现继承。
super这个关键字，既可以当作函数使用，也可以当作对象使用。作为函数时，super()只能用在子类的构造函数之中，用在其他地方就会报错。
super调用父类的方法时，super会绑定子类的this。如果super作为对象，用在静态方法之中，这时super将指向父类，而不是父类的原型对象。
`constructor`之中的`super`关键字: 当作函数使用,super()只能用在子类的构造函数之中表示父类的构造函数，用来新建父类的this对象。子类必须在constructor方法中调用super方法，否则新建实例时会报错。这是因为子类没有自己的this对象，而是继承父类的this对象，然后对其进行加工。
`getInfo`方法之中的`super`关键字: 当作对象使用,调用父类的方法。

``` javascript
class Student {
  static getAge(msg) {
    console.log('static age', msg);
  }

  getAge(msg) {
    console.log('instance age', msg);
  }
}

class Pupils extends Student {
  static myMethod(msg) {
    super.getAge(msg);
  }

  myMethod(msg) {
    super.getAge(msg);
  }
}

Pupils.myMethod(1); // static age 1

var pupils = new Pupils();
pupils.myMethod(2); // instance age 2

```
上面的例子`super`在静态方法之中指向父类，在普通方法之中指向父类的原型对象。

### this的指向
类的方法内部如果含有this，它默认指向类的实例。但是，必须非常小心，一旦单独使用该方法，很可能报错。
``` javascript
class Logger {
  printName(name = 'there') {
    this.print(`Hello ${name}`);
  }

  print(text) {
    console.log(text);
  }
}

const logger = new Logger();
const { printName } = logger;
printName(); // TypeError: Cannot read property 'print' of undefined
```
上面代码中，printName方法中的this，默认指向Logger类的实例。但是，如果将这个方法提取出来单独使用，this会指向该方法运行时所在的环境，因为找不到print方法而导致报错。
解决办法：
``` javascript
//在构造方法中绑定this，这样就不会找不到print方法了。

class Logger {
  constructor() {
    this.printName = this.printName.bind(this);
  }

  // ...
}
//使用箭头函数。

class Logger {
  constructor() {
    this.printName = (name = 'there') => {
      this.print(`Hello ${name}`);
    };
  }

  // ...
}
//使用Proxy，获取方法的时候，自动绑定this。

function selfish (target) {
  const cache = new WeakMap();
  const handler = {
    get (target, key) {
      const value = Reflect.get(target, key);
      if (typeof value !== 'function') {
        return value;
      }
      if (!cache.has(value)) {
        cache.set(value, value.bind(target));
      }
      return cache.get(value);
    }
  };
  const proxy = new Proxy(target, handler);
  return proxy;
}

const logger = selfish(new Logger());
```

### Class的 getter (取值函数)和 setter (存值函数)
与 ES5 一样，在“类”的内部可以使用`ge`t和`set`关键字，对某个属性设置存值函数和取值函数，拦截该属性的存取行为。

``` javascript
class MyClass {
  constructor() {
    // ...
  }
  get prop() {
    return 'getter';
  }
  set prop(value) {
    console.log('setter: '+value);
  }
}

let inst = new MyClass();

inst.prop = 123;
// setter: 123

inst.prop
// 'getter'
```

上面代码中，prop属性有对应的存值函数和取值函数，因此赋值和读取行为都被自定义了。

存值函数和取值函数是设置在属性的 Descriptor 对象上的。

``` javascript
class CustomHTMLElement {
  constructor(element) {
    this.element = element;
  }

  get html() {
    return this.element.innerHTML;
  }

  set html(value) {
    this.element.innerHTML = value;
  }
}

var descriptor = Object.getOwnPropertyDescriptor(
  CustomHTMLElement.prototype, "html"
);

"get" in descriptor  // true
"set" in descriptor  // true
```

上面代码中，存值函数和取值函数是定义在html属性的描述对象上面，这与 ES5 完全一致。

## 参数默认值，不定参数

### 默认值
ES6能直接为函数的参数指定默认值
``` javascript
//ES5
function animal(type){
    type = type || 'cat'  
    console.log(type)
}
animal()

//ES6

function animal(type = 'cat'){
    console.log(type)
}
animal()

```

### 不定参数
ES6 引入 rest 参数（形式为`...变量名`），用于获取函数的多余参数，这样就不需要使用arguments对象了。
``` javascript
function student(...values){
    console.log(values)
}
student('xiaoming', '18', '男') //['xiaoming', '18', '男']
```

## 模块
历史上，JavaScript 一直没有模块（module）体系，无法将一个大程序拆分成互相依赖的小文件，再用简单的方法拼装起来。
ES6的module功能，它实现非常简单，可以成为服务器和浏览器通用的模块解决方案。

### 基础用法
``` javascript
//ES5
let { stat, exists, readFile } = require('fs');
//ES6
import { stat, exists, readFile } from 'fs';

//ES5
// demo.js
export var name = 'xiaoming';
export var age = 19;
//ES6
// demo.js
var name = 'xiaoming';
var age = 19;

export {name, age};

//输出函数
export function add(x, y) {
  return x + y;
};
```

模块功能主要由两个命令构成：export和import。export命令用于规定模块的对外接口，import命令用于输入其他模块提供的功能。
import导入的变量，export输出的变量可以使用as关键字重命名:
``` javascript
var a = 1;
export {a as b};

import { a as b } from './demo';
```
ES6 模块是编译时加载，为了能进一步拓宽 JavaScript 的语法，比如引入宏（macro）和类型检验（type system）这些只能靠静态分析实现的功能。
`import`是静态执行，所以不能使用表达式和变量，这些只有在运行时才能得到结果的语法结构:
``` javascript
// error
let demo = 'demo';
import { add } from demo;

// error
if (true) {
  import { add } from 'demo';
}
```
### 整体加载模块
``` javascript
import * as demo from './demo';
demo.add()
```

### export default
`export default`命令，为模块指定默认输出。
``` javascript
// demo.js
export default function (x, y) {
  return x + y;
}

//import命令导入时可以为该默认输出指定任意名字。
import add from './demo';
add(1, 2); // 3
```
输出非匿名函数，视同匿名函数加载。`export default`一个模块只能使用一次。使用`export default`时，对应的`import`语句不需要使用大括号；不使用`export default`时，对应的`import`语句需要使用大括号:
``` javascript
// 不需要使用大括号
export default function (x, y) {
  return x + y;
}

import add from './demo';

// 需要使用大括号
export function add(x, y) {
  return x + y;
}

import {add} from './demo';
```
`export default`的本质其实就是输出一个叫做default的变量或方法，然后系统允许你为它取任意名字。
`import`语句中，同时输入默认方法和其他接口：
``` javascript
import _, { each, each as forEach } from 'lodash';
```

### import()

import()类似于 Node 的require方法，前者是异步加载，后者是同步加载。import()返回一个 Promise 对象。
``` javascript
if (true) {
	import('./demo.js')
	.then(demo => {
		demo.add(1, 2);
	})
}
```

## Promises
ES6 原生提供了Promise对象。

### 基本用法
``` javascript
promise = new Promise(function(resolve, reject) {
  // ... 
  if (error){
    reject(error);
  } else {
    resolve(value);
  }
});

promise.then((value) =>

).catch((error) =>
)
```
### Promise.all
Promise.all方法用于将多个 Promise 实例，包装成一个新的 Promise 实例。当这个数组里面所有的 Promise 对象都变为 resolve 时，该方法才会返回。`Promise.all`方法会按照数组里面的顺序将结果返回。
`Promise.race` 类似 `Promise.all`，不同的是只要该数组中的 Promise 对象的状态发生变化（无论是 resolve 还是 reject）该方法都会返回。
``` javascript
var promises = Promise.all([f1, f2, f3]);
```
### Promise.resolve()
将现有对象转为Promise对象，Promise.resolve方法就起到这个作用，实例的状态为Fulfilled。
``` javascript
Promise.resolve(true)
// 等价于
new Promise(resolve => resolve(true))
```
### Promise.reject()
返回一个新的 Promise 实例，实例的状态为rejected。

### Promise 的三种状态

Promise 对象有三种状态：
- Fulfilled 成功的状态
- Rejected 失败的状态
- Pending Promise 对象实例创建时候的初始状态

本文出自 [ECMAScript 6入门](http://es6.ruanyifeng.com/)