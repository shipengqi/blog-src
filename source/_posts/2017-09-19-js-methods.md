---
title: Javascript中的类方法、构造方法、原型方法
date: 2017-09-19 23:16:13
categories: ["Javascript"]
---

javascript中的类方法、构造方法、原型方法的对比
<!-- more -->
### 定义
``` javascript
function Class(){
//声明一个类
this.constructMethod = function(){}; //添加构造构造方法
};
Class.classMethod = function(){}; //添加类方法
Class.prototype.protoMethod=function(){};//添加原型方法
```
### 用法
``` javascript
Class.classMethod();//类方法直接调用
var instance = new Class();
instance.constructMethod();//构造方法实例才能调用
instance.protoMethod();//原型方法实例才能调用
```
### 性能
* 类方法在内存中只会有一份，因为它只属于类本身。
* 构造方法和原型方法都是实例的，但是构造方法会在每一次new Class()时，都在内存中产生一个新的副本。通常这种方法我们用在实例间的不同之处。每个实例的构造方法互不影响。
但是显然，它又占据内存了。原型方法就正好相反，它不会随着new Class()时产生新的副本，它在内存中也只有一份。可以实现实例间的共享。同时也节约了内存。
* 综上：你在开发时，一般不会用到类方法，将有共性的方法做成原型方法，将有个性的方法做成构造方法。