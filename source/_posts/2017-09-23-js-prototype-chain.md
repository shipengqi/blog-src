---
title: Javascript原型链
date: 2017-09-23 22:21:23
categories: ["Javascript"]
---
Javascript对象
每一个Javascript对象(null除外)都和另一个对象相关联，即原型，每一个对象都从原型继承属性。

<!-- more -->

## 原型链

``` javascript
function Test(value) {
  this.a = value;
};
Test.prototype.getValue = function() {
  console.log(this.a);
};
var test = new Test(1);
test.getValue(); // 输出1
```

Javascript在创建对象的时候，都有一个叫做__proto__的内置属性，用于指向创建它的函数对象的原型对象prototype。上面的代码中：
``` javascript
console.log(test.__proto__ === Test.prototype) //true
```
同样，Test.prototype对象也有__proto__属性，它指向创建它的函数对象（Object）的prototype
``` javascript
console.log(Test.prototype.__proto__ === Object.prototype) //true
```
继续，Object.prototype对象也有__proto__属性，但它比较特殊，为null
``` javascript
console.log(Object.prototype.__proto__) //null
```
我们把这个有__proto__串起来的直到Object.prototype.__proto__为null的链叫做原型链,Javascript中原形链的本质在于 `__proto__`。

## prototype和__proto__
`prototype`是函数的一个属性（每个函数都有一个`prototype`属性），这个属性是一个指针，指向一个对象。它是显示修改对象的原型的属性。
prototype 包含了2个属性，一个是constructor ，另外一个是__proto__ ,通过`hasOwnProperty`验证，constructor值为函数本身，__proto__值为父函数的prototype属性值。
`__proto__`是一个对象拥有的内置属性，是Javascript内部使用寻找原型链的属性。
> `prototype`是函数的内置属性，`__proto__`是对象的内置属性

## new 的过程
function Test() {

};

var t = new Test();

new的过程拆分成以下三步：
1. var t = {}; 初始化一个对象t
2. t.__proto__ = Test.prototype;
3. Test.call(t);

## constructor 与 prototype
我们知道每个函数都有一个默认的属性prototype，而这个prototype的constructor默认指向这个函数。例：
``` javascript
function Person(name) {
  this.name = name;
};
Person.prototype.getName = function() {
  return this.name;
};
var p = new Person("ZhangSan");

console.log(p.constructor === Person);  // true
console.log(Person.prototype.constructor === Person); // true
```
当重新定义函数的prototype时，例：
``` javascript
function Person(name) {
    this.name = name;
};

//这里prototype被覆盖
Person.prototype = {
    getName: function() {
        return this.name;
    }
};
var p = new Person("xiaoming");
console.log(p.constructor === Person);  // false
console.log(Person.prototype.constructor === Person); // false
console.log(p.constructor.prototype.constructor === Person); // false
```
因为覆盖`Person.prototype`时，等价于进行如下代码操作：
``` javascript
Person.prototype = new Object({
    getName: function() {
        return this.name;
    }
});
```
而`constructor`始终指向创建自身的构造函数，所以`Person.prototype.constructor === Object`，即是：


解决方法，重新覆盖`Person.prototype.constructor`即可：
``` javascript
Person.prototype.constructor = Person;
```




