---
title: ES6 async函数
date: 2017-09-29 19:54:36
categories: ["Javascript"]
tags: ["ES6"]
---

ES2017 标准引入了 async 函数，它就是 Generator 函数的语法糖。
Node.js 7 以上版本已经原生支持 async 和 await。

<!-- more -->

### async 函数使用
```javascript
// 函数声明
async function getMaterialDetail() {}

// 函数表达式
const getMaterialDetail = async function () {};
const getMaterialDetail = async () => {};

// 对象的方法
let GetMaterialService = { async getMaterialDetail() {} };
GetMaterialService.getMaterialDetail().then(...)

// Class 的方法
class GetMaterialService {

    async getMaterialDetail() {

    }
}

const getMaterialService = new GetMaterialService();
getMaterialService.getMaterialDetail().then(...);

```

### async函数返回Promise
async函数返回的永远是一个 Promise 对象。函数内部`return`返回的值如果不是`Promise`对象，
会自动转成状态是`fulfilled`的`Promise`对象。如果函数内部抛出错误，会返回`reject`状态的`Promise`对象。

``` javascript
async function getResolve() {
    return 'resolve'
}

getResolve().then((res) -> {
    console.log(res) //'resolve'
})

async function getReject() {
    throw new Error('reject')
}

getReject().catch((err) -> {
    console.log(err.message) //'reject'
})
```

### await

`await` 只能在`async`函数内部使用，`await`后面是一个 Promise 对象，如果不是`Promise`对象，会自动转成状态是`fulfilled`的`Promise`对象。
如果`async`函数内部有多个`await`，只要有一个`await`后面的 Promise 变为reject，那么整个async函数都会中断执行。
``` javascript
async function getResolve() {
   return await 'resolve'
}

getResolve().then((res) -> {
   console.log(res) //'resolve'
})

async function getReject() {
   await Promise.reject('reject');
   await Promise.resolve('resolve'); //不会执行
}

```
如果想让前一个异步操作失败也不会影响后面的异步操作，有两种方法，例如：
``` javascript
async function getResolve() {
  try {
    await Promise.reject('reject');
  } catch(e) {
  }
  return await Promise.resolve('resolve'); //这行代码会执行，因为上个`await`在try...catch结构里面，不管这个异步操作是否成功，都不会影响后面的异步操作
}


async function getResolve() {
  await Promise.reject('reject')
    .catch(e => console.log(e));
  return await Promise.resolve('resolve'); //这行代码会执行
}

```

### 错误处理
通过try...catch结构捕获异常。
``` javascript
async function getNews() {
  try {
    let id = await getNewsId();
    let name = await getNewsName();
    let desc = await getNewsDesc();

    return {
        id,
        name,
        desc
    }
  }
  catch (err) {
    console.error(err);
  }
}
```

### 并发执行异步操作
如上面的代码中，getNewsId、getNewsName和getNewsDesc是独立的异步操作，互不依赖，但是这里确实顺序执行，比较耗时，可以改成并发执行。
``` javascript
// 写法一
let [id, name, desc] = await Promise.all([getNewsId(), getNewsName(), getNewsDesc()]); //这里用到了解构赋值

// 写法二
let idPromise = getNewsId();
let namePromise = getNewsName();
let descPromise = getNewsDesc();
let id = await idPromise();
let name = await namePromise();
let desc = await descPromise();
```

### 参考链接

- [async 函数的含义和用法](http://www.ruanyifeng.com/blog/2015/05/async.html)
- [ECMAScript 6 入门](http://es6.ruanyifeng.com/#docs/async)