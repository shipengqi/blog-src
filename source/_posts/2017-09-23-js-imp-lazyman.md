---
title: Javascript 实现Lazyman
date: 2017-09-23 21:19:54
categories: ["Javascript"]
tags: ["ES6"]
---

Lazyman其实就是实现 LazyMan('Hank').sleep(1000).eat('dinner')这样的形式的链式调用。 
<!-- more -->
``` javascript
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
}

//尾调用函数，一个任务执行完然后再调用下一个任务
_LazyMan.prototype.next = function() {
    var _fn = this.tasks.shift();
    _fn && _fn();
/*    if(fn){
        fn()
    }*/
}
_LazyMan.prototype.sleep = function(_time) {
    var _this = this;
    _this.tasks.push(function() {
        setTimeout(function() {
            console.log('Wake up after ' + _time);
            _this.next();
        }, _time);
    });

    //实现链式调用必须要返回this，否则调用下个方法会error: Cannot read property <method> of undefined
    return _this;
}

//sleepFirst函数需要最先执行，所以我们需要在任务队列前面放入，然后再执行后面的任务
_LazyMan.prototype.sleepFirst = function(_time) {
    var _this = this;
    _this.tasks.unshift(function() {
        setTimeout(function() {
            console.log('Wake up after ' + _time);
            _this.next();
        }, _time);
    });
    return _this;
}
_LazyMan.prototype.eat = function(_eat) {
    var _this = this;
    _this.tasks.push(function() {
        console.log('Eat ' + _eat);
        _this.next();
    });
    return _this;
}

// 因为调用Lazyman的时候不需要用到new关键字，所以封装一个工厂函数
var LazyMan = function(_name) {
    return new _LazyMan(_name);
}

LazyMan('Hank').sleep(1000).eat('dinner')
LazyMan('Hank').sleepFirst(5000).eat('supper')
```

ES6 实现
``` javascript
class _LazyMan {
  constructor(name) {
    this.tasks = [];
    let task = (name => () => {
      console.log(`Hi! This is ${name} !`);
      this.next();
    })(name);
    this.tasks.push(task);

    setTimeout(() => {
      this.next();
    }, 0);

  }

  next() {
    let task = this.tasks.shift();
    task && task();
  }

  eat(food) {
    let task = (food => () => {
      console.log(`Eat ${food}`);
      this.next();
    })(food);
    this.tasks.push(task);
    return this;
  }

  sleep(time) {
    let task = (time => () => {
      setTimeout(() => {
        console.log(`Wake up after ${time} s!`);
        this.next();
      }, time)
    })(time);
    this.tasks.push(task);
    return this;
  }

  sleepFirst(time) {
    let task = (time => () => {
      setTimeout(() => {
        console.log(`Wake up after ${time} s!`);
        this.next();
      }, time)
    })(time);
    this.tasks.unshift(task);
    return this;
  }

}
```