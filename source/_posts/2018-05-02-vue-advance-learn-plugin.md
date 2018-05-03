---
title: Vue.js 深入学习 插件
date: 2018-05-02 10:53:37
categories: ["前端"]
tags: ["Vue.js"]
---

Vue插件，可以添加全局功能。
<!-- more -->
例如：

- 添加全局方法或者属性，如: vue-custom-element
- 添加全局资源：指令/过滤器/过渡等，如 vue-touch
- 通过全局 mixin 方法添加一些组件选项，如: vue-router
- 添加 Vue 实例方法，通过把它们添加到 Vue.prototype 上实现。
- 一个库，提供自己的 API，同时提供上面提到的一个或多个功能，如 vue-router

<!-- more -->

## 注册插件
Vue.js 的插件要有一个公开方法 install。该方法第一个参数是 Vue 构造器，第二个参数是一个可选的对象：
```javascript
MyPlugin.install = function (Vue, options) {
  //添加全局方法或属性
  Vue.myGlobalMethod = function () {
    // 逻辑...
  }

  //添加全局资源
  Vue.directive('my-directive', {
    bind (el, binding, vnode, oldVnode) {
      // 逻辑...
    }
    ...
  })

  //添加全局混合
  Vue.mixin({
    created: function () {
      // 逻辑...
    }
    ...
  })

  //添加实例方法
  Vue.prototype.$myMethod = function (methodOptions) {
    // 逻辑...
  }
}
```

## 使用插件
```html
// 调用 `MyPlugin.install(Vue)`
Vue.use(MyPlugin, {})
```
Vue.use 会自动阻止多次注册相同插件。
