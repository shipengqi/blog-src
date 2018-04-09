---
title: Javascript深入学习 面向对象
date: 2018-02-27 17:16:05
categories: ["Javascript"]
tags: ["Javascript深入学习系列"]
---

面向对象编程（Object Oriented Programming，缩写为 OOP）是目前主流的编程范式。

<!-- more -->


## 面向对象

### 理解对象
属性类型：只有内部才用的特性（attribute），描述了属性（property）的各种特征。
ECMAScript中有两种属性：数据属性和访问器属性。
#### 数据属性
数据属性包含一个数据值的位置。在这个位置可以读取和写入值。数据属性有4个描述其行为的特性：

- Configurable：表示能否通过delete删除属性从而重新定义属性，能否修改属性的特性，或者能否把属性修改为访问器属性。默认值为true。
- Enumerable：表示能否通过for-in循环返回属性。默认值为true。
- Writable：表示能否修改属性的值。默认值为true。
- Value：包含这个属性的数据值。读取属性值的时候，从这个位置读；写入属性值的时候，把新值保存在这个位置。这个特性的默认值为undefined。

要修改属性默认的特性，必须使用Object.defineProperty()方法。这个方法接收三个参数：属性所在的对象、属性的名字和一个描述符对象。
``` javascript
var person = {};
Object.defineProperty(person, "name", {
    writable: false,
    value: "xiaoming"
});
console.log(person.name); //"xiaoming"
person.name = "xiaoliang";
console.log(person.name); //"xiaoming"
```
name属性是只读的，不可修改，在非严格模式下，赋值操作将被忽略；在严格模式下，赋值操作将会导致抛出错误。

> 一旦把属性定义为不可配置的，也就是把configurable设置为false，就不能再把它变回可配置了。再调用Object.defineProperty()方法修改除writable之外的特性，都会导致错误。

#### 访问器属性
访问器属性不包含数据值；它们包含一对儿getter和setter函数。
访问器属性有如下4个特性：
- Configurable：同数据属性。
- Enumerable：同数据属性。
- Get：在读取属性时调用的函数。默认值为undefined。
- Set：在写入属性时调用的函数。默认值为undefined。

同数据属性一样必须使用Object.defineProperty()来定义。
``` javascript
var book = { _year: 2004, edition: 1 };
Object.defineProperty(book, "year", {
    get: function(){
        return this._year;
    },
    set: function(newValue){
        if (newValue > 2004) {
            this._year = newValue;
            this.edition += newValue - 2004;
        }
    }
});

book.year = 2005;
console.log(book.edition); //2
```

> 不一定非要同时指定getter和setter。只指定getter意味着属性是不能写，尝试写入属性会被忽略。在严格模式下，尝试写入只指定了getter函数的属性会抛出错误。
只指定setter函数的属性也不能读。否则在非严格模式下会返回undefined，而在严格模式下会抛出错误。

#### 定义多个属性
定义多个属性使用bject.definePro- perties()方法。
这个方法接收两个对象参数：第一个对象是要添加和修改其属性的对象，第二个对象的属性与第一个对象中要添加或修改的属性一一对应。

``` javascript
var book = {};
Object.defineProperties(book, {
    _year: { value: 2004 },
    edition: { value: 1 },
    year: { get: function(){
                return this._year;
            },
            set: function(newValue){
                if (newValue > 2004) {
                    this._year = newValue;
                    this.edition += newValue - 2004;
                }
            }
          }
});
```

#### 读取属性的特性
Object.getOwnPropertyDescriptor()方法，可以取得给定属性的描述符。这个方法接收两个参数：属性所在的对象和要读取其描述符的属性名称。
返回值是一个对象，如果是访问器属性，这个对象的属性有configurable、enumerable、get和set；如果是数据属性，这个对象的属性有configurable、enumerable、writable和value。

### 理解原型

面向对象编程很重要的一个方面，就是对象的继承。A 对象通过继承 B 对象，就能直接拥有 B 对象的所有属性和方法。这对于代码的复用是非常有用的。

大部分面向对象的编程语言，都是通过“类”（class）来实现对象的继承。JavaScript 语言的继承则是通过“原型对象”（prototype）。

#### 构造函数的缺点

JavaScript 通过构造函数生成新对象，因此构造函数可以视为对象的模板。实例对象的属性和方法，可以定义在构造函数内部。

```javascript
function Cat (name, color) {
  this.name = name;
  this.color = color;
}

var cat1 = new Cat('大毛', '白色');

cat1.name // '大毛'
cat1.color // '白色'
```

上面代码中，`Cat`函数是一个构造函数，函数内部定义了`name`属性和`color`属性，所有实例对象（上例是`cat1`）都会生成这两个属性，即这两个属性会定义在实例对象上面。

通过构造函数为实例对象定义属性，虽然很方便，但是有一个缺点。同一个构造函数的多个实例之间，无法共享属性，从而造成对系统资源的浪费。

```javascript
function Cat(name, color) {
  this.name = name;
  this.color = color;
  this.meow = function () {
    console.log('喵喵');
  };
}

var cat1 = new Cat('大毛', '白色');
var cat2 = new Cat('二毛', '黑色');

cat1.meow === cat2.meow
// false
```

上面代码中，`cat1`和`cat2`是同一个构造函数的两个实例，它们都具有`meow`方法。由于`meow`方法是生成在每个实例对象上面，所以两个实例就生成了两次。也就是说，每新建一个实例，就会新建一个`meow`方法。这既没有必要，又浪费系统资源，因为所有`meow`方法都是同样的行为，完全应该共享。

这个问题的解决方法，就是 JavaScript 的原型对象（prototype）。

#### prototype 属性的作用

JavaScript 继承机制的设计思想就是，原型对象的所有属性和方法，都能被实例对象共享。也就是说，如果属性和方法定义在原型上，那么所有实例对象就能共享，不仅节省了内存，还体现了实例对象之间的联系。

下面，先看怎么为对象指定原型。JavaScript 规定，每个函数都有一个`prototype`属性，指向一个对象。

```javascript
function f() {}
typeof f.prototype // "object"
```

上面代码中，函数`f`默认具有`prototype`属性，指向一个对象。

对于普通函数来说，该属性基本无用。但是，对于构造函数来说，生成实例的时候，该属性会自动成为实例对象的原型。

```javascript
function Animal(name) {
  this.name = name;
}
Animal.prototype.color = 'white';

var cat1 = new Animal('大毛');
var cat2 = new Animal('二毛');

cat1.color // 'white'
cat2.color // 'white'
```

上面代码中，构造函数`Animal`的`prototype`属性，就是实例对象`cat1`和`cat2`的原型对象。原型对象上添加一个`color`属性，结果，实例对象都共享了该属性。

原型对象的属性不是实例对象自身的属性。只要修改原型对象，变动就立刻会体现在**所有**实例对象上。

当实例对象本身没有某个属性或方法的时候，它会到原型对象去寻找该属性或方法。这就是原型对象的特殊之处。

如果实例对象自身就有某个属性或方法，它就不会再去原型对象寻找这个属性或方法。


#### 原型链

JavaScript 规定，所有对象都有自己的原型对象（prototype）。一方面，任何一个对象，都可以充当其他对象的原型；另一方面，由于原型对象也是对象，所以它也有自己的原型。

因此，就会形成一个“原型链”（prototype chain）：对象到原型，再到原型的原型……

如果一层层地上溯，所有对象的原型最终都可以上溯到`Object.prototype`，即`Object`构造函数的`prototype`属性。也就是说，所有对象都继承了`Object.prototype`的属性。

这就是所有对象都有`valueOf`和`toString`方法的原因，因为这是从`Object.prototype`继承的。

那么，`Object.prototype`对象有没有它的原型呢？回答是`Object.prototype`的原型是`null`。`null`没有任何属性和方法，也没有自己的原型。因此，原型链的尽头就是`null`。

```javascript
Object.getPrototypeOf(Object.prototype)
// null
```

上面代码表示，`Object.prototype`对象的原型是`null`，由于`null`没有任何属性，所以原型链到此为止。`Object.getPrototypeOf`方法返回参数对象的原型，具体介绍请看后文。

读取对象的某个属性时，JavaScript 引擎先寻找对象本身的属性，如果找不到，就到它的原型去找，如果还是找不到，就到原型的原型去找。如果直到最顶层的`Object.prototype`还是找不到，

则返回`undefined`。如果对象自身和它的原型，都定义了一个同名属性，那么优先读取对象自身的属性，这叫做“覆盖”（overriding）。

注意，一级级向上，在整个原型链上寻找某个属性，对性能是有影响的。所寻找的属性在越上层的原型对象，对性能的影响越大。如果寻找某个不存在的属性，将会遍历整个原型链。

举例来说，如果让构造函数的`prototype`属性指向一个数组，就意味着实例对象可以调用数组方法。

```javascript
var MyArray = function () {};

MyArray.prototype = new Array();
MyArray.prototype.constructor = MyArray;

var mine = new MyArray();
mine.push(1, 2, 3);
mine.length // 3
mine instanceof Array // true
```

上面代码中，`mine`是构造函数`MyArray`的实例对象，由于`MyArray.prototype`指向一个数组实例，使得`mine`可以调用数组方法（这些方法定义在数组实例的`prototype`对象上面）。

最后那行`instanceof`表达式，用来比较一个对象是否为某个构造函数的实例，结果就是证明`mine`为`Array`的实例，`instanceof`运算符的详细解释详见后文。


#### constructor 属性

`prototype`对象有一个`constructor`属性，默认指向`prototype`对象所在的构造函数。

```javascript
function P() {}
P.prototype.constructor === P // true
```

由于`constructor`属性定义在`prototype`对象上面，意味着可以被所有实例对象继承。

```javascript
function P() {}
var p = new P();

p.constructor === P // true
p.constructor === P.prototype.constructor // true
p.hasOwnProperty('constructor') // false
```

上面代码中，`p`是构造函数`P`的实例对象，但是`p`自身没有`constructor`属性，该属性其实是读取原型链上面的`P.prototype.constructor`属性。

`constructor`属性的作用是，可以得知某个实例对象，到底是哪一个构造函数产生的。

```javascript
function F() {};
var f = new F();

f.constructor === F // true
f.constructor === RegExp // false
```

上面代码中，`constructor`属性确定了实例对象`f`的构造函数是`F`，而不是`RegExp`。

另一方面，有了`constructor`属性，就可以从一个实例对象新建另一个实例。

```javascript
function Constr() {}
var x = new Constr();

var y = new x.constructor();
y instanceof Constr // true
```

上面代码中，`x`是构造函数`Constr`的实例，可以从`x.constructor`间接调用构造函数。这使得在实例方法中，调用自身的构造函数成为可能。

```javascript
Constr.prototype.createCopy = function () {
  return new this.constructor();
};
```

上面代码中，`createCopy`方法调用构造函数，新建另一个实例。

`constructor`属性表示原型对象与构造函数之间的关联关系，如果修改了原型对象，一般会同时修改`constructor`属性，防止引用的时候出错。

```javascript
function Person(name) {
  this.name = name;
}

Person.prototype.constructor === Person // true

Person.prototype = {
  method: function () {}
};

Person.prototype.constructor === Person // false
Person.prototype.constructor === Object // true
```

上面代码中，构造函数`Person`的原型对象改掉了，但是没有修改`constructor`属性，导致这个属性不再指向`Person`。由于`Person`的新原型是一个普通对象，

而普通对象的`contructor`属性指向`Object`构造函数，导致`Person.prototype.constructor`变成了`Object`。

所以，修改原型对象时，一般要同时修改`constructor`属性的指向。

```javascript
// 坏的写法
C.prototype = {
  method1: function (...) { ... },
  // ...
};

// 好的写法
C.prototype = {
  constructor: C,
  method1: function (...) { ... },
  // ...
};

// 更好的写法
C.prototype.method1 = function (...) { ... };
```

上面代码中，要么将`constructor`属性重新指向原来的构造函数，要么只在原型对象上添加方法，这样可以保证`instanceof`运算符不会失真。

如果不能确定`constructor`属性是什么函数，还有一个办法：通过`name`属性，从实例得到构造函数的名称。

```javascript
function Foo() {}
var f = new Foo();
f.constructor.name // "Foo"
```

#### instanceof 运算符

`instanceof`运算符返回一个布尔值，表示对象是否为某个构造函数的实例。

```javascript
var v = new Vehicle();
v instanceof Vehicle // true
```

上面代码中，对象`v`是构造函数`Vehicle`的实例，所以返回`true`。

`instanceof`运算符的左边是实例对象，右边是构造函数。它会检查右边构建函数的原型对象（prototype），是否在左边对象的原型链上。因此，下面两种写法是等价的。

```javascript
v instanceof Vehicle
// 等同于
Vehicle.prototype.isPrototypeOf(v)
```


由于`instanceof`检查整个原型链，因此同一个实例对象，可能会对多个构造函数都返回`true`。

```javascript
var d = new Date();
d instanceof Date // true
d instanceof Object // true
```

上面代码中，`d`同时是`Date`和`Object`的实例，因此对这两个构造函数都返回`true`。

`instanceof`的原理是检查右边构造函数的`prototype`属性，是否在左边对象的原型链上。有一种特殊情况，就是左边对象的原型链上，只有`null`对象。这时，`instanceof`判断会失真。

```javascript
var obj = Object.create(null);
typeof obj // "object"
Object.create(null) instanceof Object // false
```

上面代码中，`Object.create(null)`返回一个新对象`obj`，它的原型是`null`（`Object.create`的详细介绍见后文）。右边的构造函数`Object`的`prototype`属性，

不在左边的原型链上，因此`instanceof`就认为`obj`不是`Object`的实例。但是，只要一个对象的原型不是`null`，`instanceof`运算符的判断就不会失真。

`instanceof`运算符的一个用处，是判断值的类型。

```javascript
var x = [1, 2, 3];
var y = {};
x instanceof Array // true
y instanceof Object // true
```

上面代码中，`instanceof`运算符判断，变量`x`是数组，变量`y`是对象。

注意，`instanceof`运算符只能用于对象，不适用原始类型的值。

```javascript
var s = 'hello';
s instanceof String // false
```

上面代码中，字符串不是`String`对象的实例（因为字符串不是对象），所以返回`false`。

此外，对于`undefined`和`null`，`instanceOf`运算符总是返回`false`。

```javascript
undefined instanceof Object // false
null instanceof Object // false
```

利用`instanceof`运算符，还可以巧妙地解决，调用构造函数时，忘了加`new`命令的问题。

```javascript
function Fubar (foo, bar) {
  if (this instanceof Fubar) {
    this._foo = foo;
    this._bar = bar;
  } else {
    return new Fubar(foo, bar);
  }
}
```

上面代码使用`instanceof`运算符，在函数体内部判断`this`关键字是否为构造函数`Fubar`的实例。如果不是，就表明忘了加`new`命令。

### this关键字

`this`关键字可以用在构造函数之中，表示实例对象。除此之外，`this`还可以用在别的场合。但不管是什么场合，`this`都有一个共同点：它总是返回一个对象。
具体参考我[之前的博客](/2017/09/23/js-this/)

### 继承
具体参考我[之前的博客](/2017/09/23/js-extend/)

## 函数表达式

JavaScript中定义函数的方式有两种：一种是函数声明，另一种就是函数表达式。
关于函数声明，它的一个重要特征就是**函数声明提升**。

### 闭包
匿名函数和闭包容易混淆，闭包是指有权访问另一个函数作用域中的变量的函数。创建闭包的常见方式，就是在一个函数内部创建另一个函数。
具体参考我之前的[一篇博客](/2017/09/19/js-closure/)

### 私有变量

JavaScript中没有私有成员的概念；所有对象属性都是公有的。不过，倒是有一个私有变量的概念。任何在函数中定义的变量，都可以认为是私有变量，因为不能在函数的外部访问这些变量。


