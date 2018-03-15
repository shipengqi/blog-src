---
title: Javascript 常用的设计模式
date: 2017-10-09 20:36:00
categories: ["Javascript"]
---
总结平时相对来说用的比较多的设计模式。
设计模式的一个原则：对修改关闭，对扩展开放。
<!-- more -->

## 单例模式

单例模式是最常用的、最基本的设计模式，单例就是保证一个类只有一个实例，并且提供一个访问它的全局访问点。
惰性单例：在需要的时候才创建对像，并且只创建一次。
``` javascript
```
nodejs实现单例:
``` javascript
//test.js
module.exports = new SingleTon()

//demo.js
var singleTon = require('test.js');
```

nodejs的模块加载机制，模块在第一次加载后会被缓存，也就是单例，因此，每次调用require('test.js')的时候都会返回同一个对象。如果需要一个模块多次执行，就要输出一个函数，通过调用这个函数实现模块代码的多次执行。

## 工厂模式
工厂模式是一种有助于消除两个类依赖性的模式。弱化对象间的耦合，防止代码的重复。
简单工厂模式：使用一个类（通常为单体）来生成实例。
复杂工厂模式：将其成员对象的实列化推迟到子类中，子类可以重写父类接口方法以便创建的时候指定自己的对象类型。
父类只对创建过程中的一般性问题进行处理，这些处理会被子类继承，子类之间是相互独立的，具体的业务逻辑会放在子类中进行编写。
父类就变成了一个抽象类，但是父类可以执行子类中相同类似的方法，具体的业务逻辑需要放在子类中去实现；比如我现在开几个自行车店，那么每个店都有几种型号的自行车出售。

### 简单工厂模式
``` javascript
class BicycleFactory {
  createBicycle(model) {
    let bicycle;
	switch(model){
	  case "The Speedster":
	    bicycle = new Speedster();
	    break;
	  case "The Lowrider":
	    bicycle = new Lowrider();
	    break;
	  default:
	    bicycle = new Cruiser();
	    break;
	}
	return bicycle;
  }
}

bicycleFactory = new BicycleFactory();

class BicycleShop {
	sellBicycle(model) {
	    var bicycle = bicycleFactory.createBicycle(model);
	    return bicycle;
	}
}

```
上面的代码就是一个简单工厂模式的实例。该模式将成员对象的创建工作交给一个外部对象实现，该外部对象可以是一个简单的命名空间，也可以是一个类的实例。
### 复杂工厂模式
真正的工厂模式与简单工厂模式相比，主要区别就是它不是另外使用一个对象或者类来创建实例（自行车），而是使用一个子类。工厂是一个将其成员对象的实例化推迟到子类中进行的类。
比如加入BicycleShop可以决定从那一家厂商进行进货，那么简单的一个BicycleFactory是不够了的，因为各个厂商会各自生产不同的Speedster，Lowrider，Cruiser等型号自行车，所以首先需要生成各自厂商的shop实例，不同厂商的shop实例拥有不同的生成几个型号自行车的方法。

也就是相当于将自行车对象的实例化推迟到了shop实例中产生。

``` javascript
class BicycleShop {
	sellBicycle(model) {
	    var bicycle = this.createBicycle(model);
	    return bicycle;
	}

	createBicycle(model) {
        throw new Error( "This is an abstract class" );
    }
}


//各自厂商

class AcmeBicycleShop extends BicycleShop {
	createBicycle(model) {
        var bicycle;
	    switch(model){
	        case "The Speedster":
	            bicycle = new AcmeSpeedster();
	            break;
	        case "The Lowrider":
	            bicycle = new AcmeLowrider();
	            break;
	        case "The Cruiser":
	        default:
	            bicycle = new AcmeCruiser();
	            break;
	    }
	    return bicycle;
	}
}


class GeneralBicycleShop extends BicycleShop {
	createBicycle(model) {
		...
	}
}

//接下来就很简单 对于来自 Acme 进货的
var acmeShop = new AcmeBicycleShop();
var newBicycle = acmeShop.sellBicycle("The Speedster");
```

## 发布订阅模式(观察者模式)
它定义了对象间的一种一对多的依赖关系，以便当一个对象的状态发生改变时，所有依赖于它的对象都将得到通知。
这个模式比较好理解，比如比A,B,C都订阅了同一个公众号，当公众号有更新时，A、B、C都会收到通知。

``` javascript
calss WeChatSub {
    constructor() {
       this.subscribers = {};
    }
    publish(content) {
        //没有人订阅
        if(this.subscribers.length === 0){
            return false;
        }
        for(let v in this.subscribers) {
            v.cb(content)
        }
    }
    subscribe(uid, cb) {
        // 已经订阅过
        if (this.subscribers[uid]) {
            return uid
        }

        // 每订阅一个，就把它存入到我们的数组中去
        this.subscribers[uid] = {
            uid: uid,
            cb: cb
        });
        return uid;
    }

    unSubscribe(uid) {
        // 未订阅
        if (!this.subscribers[uid]) {
            return false
        }

        delete this.subscribers[uid];
        return uid;
    }
}


let weChatSub = new WeChatSub();
//将订阅赋值给一个变量，以便退订
let A = weChatSub.subscribe(123, function (content) {
    console.logcontent);
});
let B = weChatSub.subscribe(456, function (content) {
    console.log(content);
});


//发布
weChatSub.publish('新内容');

weChatSub.unsubscribe(123);
```

## 代理模式
简单说就是把对一个对象的访问, 交给另一个代理对象来操作。

比如送外卖，餐厅的外卖订单找外卖骑士代送：
``` javascript
class Consumer {
    constructor(name) {
        this.name = name;
    }
};

class Restaurant {
    constructor(consumer) {
        this.consumer = consumer
    }

    delivery (takeout) {
        console.log(`派送外卖: ${takeout}， 收件人: ${this.consumer.name}`);
    }
};

class Courier {
    constructor(consumer) {
        this.consumer = consumer
    }

    delivery (takeout) {
        restaurant = new Restaurant(this.consumer)
        restaurant.delivery(takeout)
    }
};

var proxy = new Courier(new Consumer("xiaoming"));
proxy.delivery("奶茶"); // 派送外卖: 奶茶， 收件人: xiaoming
```

## 策略模式
定义一系列的算法，把它们一个个封装起来，并且使它们可以相互替换。简单说就是把有很多判断的写法，现在把判断里面的内容抽离开来，变成一个个小的个体。

比如公司的年终奖按绩效发放，绩效等级分为A，B，C，奖金等于月薪水乘倍数，下面的代码没有使用策略模式：
``` javascript
var computeBouns = function(salary,level) {
    if(level === 'A') {
        return salary * 2;
    }
    if(level === 'B') {
        return salary * 1.5;
    }
    if(level === 'C') {
        return salary;
    }
};

computeBouns(5000,'A'); // 10000
```
缺点：当要加入D，E，或者绩效倍数要修改，就要不断的修改if..else的条件了。
使用策略模式重构代码：
``` javascript
class PerformanceA {
    constructor() {
       this.multiple = 2;
    }
    getBouns(salary) {
        return salary * this.multiple;
    }
}

class PerformanceB {
    constructor() {
       this.multiple = 1.5;
    }
    getBouns(salary) {
        return salary * this.multiple;
    }
}

class PerformanceC {
    constructor() {
       this.multiple = 1;
    }
    getBouns(salary) {
        return salary * this.multiple;
    }
}

class Bouns {
    constructor() {
        this.salary = null;    // 原始工资
        this.strategy = null;  // 绩效等级策略
    }
    set(salary, strategy) {
        this.salary = salary;    // 原始工资
        this.strategy = strategy;  // 绩效等级策略
    }

    getBouns() {
        return this.strategy.getBouns(this.salary);
    }
}


var bouns = new Bouns();
bouns.set (5000, new PerformanceA());
bouns.getBouns();  // 10000
```

## 模版模式
包括两部分：
1. 抽象父类，封装了子类的算法框架，实现一些公共方法
2. 具体实现的子类，子类继承这个父类，可以在子类中重写父类的方法，实现具体的业务逻辑。

比如面试，很多公司的面试过程其实很类似，但是每个公司具体的笔试题，但是面试题不一样。
``` javascript

class Interview {
    writtenTest() {
        console.log("笔试题");
    }

    technicalInterview() {
        console.log("技术面试");
    }

    HRInterview() {
        console.log("HR面试");
    }

    waitNotice() {
        console.log("等通知");
    }
}

// HP面试 重写父类方法
class HPInterview extends Interview {
    writtenTest() {
        console.log("不一样的笔试题");
    }

    technicalInterview() {
        console.log("不一样的技术面试");
    }
}
```