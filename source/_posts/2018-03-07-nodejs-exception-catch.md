---
title: NodeJs中的异常处理
date: 2018-03-07 10:10:48
categories: ["NodeJs"]
---

NodeJs中的异常处理是一个应该注意的点。

<!-- more -->

## try/catch

通常我们在代码中捕获异常，会用下面的方式：

``` javascript
try {
  //process
} catch (e) {
  errorHandler(e)
}
```

但是在Nodejs中，这种方式对于处理异步编程并不一定适用，例如：

``` javascript
function asyncFunc (callback) {
  process.nextTick(callback);
}
try {
  asyncFunc(callback);
} catch (e) {
  errorHandler(e)
}
```

上面的代码中，调用`asyncFunc(callback)`，`callback`在下一个事件循环才会执行，但是`try/catch`只能捕获当前事件循环内的异常，
所以当`callback`执行时抛出的异常将无法捕获。

## 不要对回调函数进行异常捕获

如下下面的写法：

``` javascript
try {
  process();
  callback(null, result);
} catch (e) {
  callback(e, result);
}
```

上面的代码中，不仅会捕获`process()`中的异常，`callback()`中的异常一样会捕获，所以如果`callback()`执行抛出异常，`catch()`代码块一样会捕获，
这样的话`callback()`将会执行两次，正确的写法应该是：

``` javascript
try {
  process();
} catch (e) {
  return callback(e, result);
}

callback(null, result);
```

## 处理异常的常规写法

通常回调函数的第一个参数是异常，如果第一个参数为空，则表示没有异常。
