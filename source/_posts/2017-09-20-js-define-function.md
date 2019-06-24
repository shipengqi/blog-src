---
title: JavaScript定义函数
date: 2017-09-20 19:54:12
categories: ["Javascript"]
---

JavaScript定义函数有多种方式。在JavaScript中每个函数都是一个Function对象，它不仅能像对象一样拥有属性和方法，而且可以被调用。
<!-- more -->
### 比较常用的方式
1. 函数声明 (函数语句)
``` javascript
function add(x, y) {
    return x + y;
}
```
2. 函数表达式
``` javascript
var add = function(x, y) {
    return x + y;
};
```
3. Function构造函数
``` javascript
var add = new Function("a", "b", "return a + b");
```
> 不推荐,构造函数使用字符串做为函数体，这会阻止JS引擎的语法检查及优化等。
> 使用函数声明定义的函数名不能被改变，而使用函数表达式定义的函数变量可以再被赋值。函数声名会带来作用域的提升,也就是可以在定义函数前调用。
  例如：
  ``` javascript
  add(1, 2)
  function add(x, y) {
      return x + y;
  }
  ```
> Function构造函数定义的函数确不同，构造函数被调用一次，其中的函数体字符串都要被解析一次。而函数表达式定义的函数和通过函数声明定义的函数不会。
