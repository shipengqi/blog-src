---
title: ES6装饰器
date: 2017-09-28 20:12:17
categories: ["Javascript"]
tags: ["ES6"]
---

ES6 引入了装饰器（Decorator），目前还是提案。但是Babel 转码器已经支持 Decorator。

<!-- more -->

## Decorator基本用法
### 修饰类

``` javascript
@testDecorator
class MyClass {

}


function testDecorator(target) {
  //添加静态属性
  target.isTestable = true;
  //添加实例属性
  //target.prototype.isTestable = true;
}

MyClass.isTestable // true

//let instance = new MyClass();
//instance.isTestable // true ,实例属性
```

上面的代码@testDecorator是一个装饰器,这里装饰器的参数target是MyClass类本身。
这个装饰器为MyClass加上了静态属性isTestable。
如果想要给装饰器传参，下面的例子：
``` javascript
@testDecorator
class MyClass {

}

function testDecorator(isTestable) {
  return function(target) {
    target.isTestable = isTestable;
  }
}

@testDecorator(true)
class MyClass {}
MyTestableClass.isTestable // true
```

> 修饰器是编译时执行的函数。

### 修饰方法

``` javascript
@log
@interfaceCache
async getData(params) {
  return await db.getData(params)
}

function log(target, name, descriptor) {
    // descriptor对象原来的值如下
    // {
    //   value: specifiedFunction,
    //   enumerable: false,
    //   configurable: true,
    //   writable: true
    // };
    let oldValue = descriptor.value;

    descriptor.value = function(...args) {
        monitor.info(`Calling interface "${name}" with params : ${JSON.stringify(args)}`);
        return oldValue.apply(this, args);
    };

    return descriptor;
}

function interfaceCache(target, name, descriptor) {
    let oldValue = descriptor.value;

    let cacheService = new RedisCacheService() //连接redis实例

    //获取缓存数据
    const get = async (key) => {
        return await cacheService.getCache(key);
    };

    //存入缓存数据
    const set = async (key,data) => {
        return await cacheService.setCache(key, data, REDIS_EXPIRE_MATERIAL_LIST);
    };

    descriptor.value = async function (...args) {
        //这里buildRedisKey方法根据方法的name和参数生成key
        let Key = buildRedisKey(name, args);
        //获取缓存
        let cacheData = await get(Key);

        if(cacheData){//如果拿到缓存直接返回缓存的数据
            return cacheData;
        }else{
            //没有缓存数据，执行方法
            let data = await oldValue.apply(this, args);
            //缓存数据
            await set(Key, data);
            return data;
        }
    };

    return descriptor;
}
```

上面代码中，修饰器@log, @interfaceCache用来修饰`类`的`getData`方法。

此时，修饰器函数的三个参数：
1. target：修饰的目标对象，即类的实例（这不同于类的修饰，那种情况时target参数指的是类本身）
2. name：修饰的属性名
3. descriptor：该属性的描述对象

@log用来输出该方法的访问日志。
@interfaceCache用来做接口缓存，
如果同一个方法有多个修饰器，会先从外到内进入，然后由内向外执行。也就是外层修饰器@log先进入，但是内层修饰器@interfaceCache先执行。

### babel转码
安装`babel-core`和`babel-plugin-transform-decorators`。由于后者包括在`babel-preset-stage-0`之中，所以改为安装`babel-preset-stage-0`亦可。
``` bash
$ npm install babel-core babel-plugin-transform-decorators
```

修改`.babelrc`文件。
```
{
    "presets": ["stage-0","es2015"],
    "plugins": [
        "transform-decorators-legacy",
        "transform-class-properties"
    ]
}
```

#### 实时转码

添加启动文件start.js
``` javascript
require('babel-register');
require('babel-polyfill');

require('./src/index.js');
```
index.js 根据自己的项目修改为你的项目入口文件。

#### 命令转码

``` bash
babel ./src --out-dir ./dist/src
```

本文出自 [ECMAScript 6 入门](http://es6.ruanyifeng.com/#docs/decorator)
