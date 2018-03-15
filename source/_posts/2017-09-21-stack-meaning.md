---
title: Stack的含义
date: 2017-09-21 22:01:42
categories: ["编程"]
tags: []
---

栈的三个含义


1. 数据结构
这里的stack是一种数据结构，在这种数据结构中，数据层层累积，先加入的数据在底层，后加入的数据在上层。使用时，上层的数据会先被取出来，这就叫做"后进先出"。

<!-- more -->

2. 代码的运行方式
这里的stack表示"调用栈"，函数方法像堆积木一样存放，以实现层层调用。
下面以一段Java代码为例
``` javascript
class Student{
    constructor(name, age) {
        this.name = name;
        this.age = age;
        this.sayHello();
    }

    sayHello() {
        return `Hello ${this.name}`;
    }
}

function main() {
    student = new Student('zhangsan', 25);
}
main()
```

上面这段代码运行的时候，先运行main方法，main方法生成一个Student的实例，于是又调用Student构造函数。在构造函数中，又调用到sayHello方法。

这三次调用像积木一样堆起来，就叫做"调用栈"。程序运行的时候，总是先完成最上层的调用，然后将它的值返回到下一层调用，直至完成整个调用栈，返回最后的结果。

3. 内存区域
stack的第三种含义是存放数据的一种内存区域。程序运行的时候，需要内存空间存放数据。一般来说，系统会划分出两种不同的内存空间：一种叫做stack（栈），另一种叫做heap（堆）。

它们的主要区别是：stack是有结构的，每个区块按照一定次序存放，可以明确知道每个区块的大小；heap是没有结构的，数据可以任意存放。因此，stack的寻址速度要快于heap。

其他的区别还有，一般来说，每个线程分配一个stack，每个进程分配一个heap，也就是说，stack是线程独占的，heap是线程共用的。此外，stack创建的时候，大小是确定的，数据超过这个大小，就发生stack overflow错误，而heap的大小是不确定的，需要的话可以不断增加。
根据上面这些区别，数据存放的规则是：只要是局部的、占用空间确定的数据，一般都存放在stack里面，否则就放在heap里面。

``` javascript
function main() {
    let name = 'zhangsan';
    let age = 25
    let student = new Student(name, age);
}
```

main方法，共包含了三个变量：name, age 和 student。其中，name和age的内存占用空间是确定的，而且是局部变量，只用在main区块之内，不会用于区块之外。student也是局部变量，但是类型为指针变量，指向一个对象的实例。指针变量占用的大小是确定的，但是对象实例以目前的信息无法确知所占用的内存空间大小。

name, age 和 student都存放在stack，因为它们占用内存空间都是确定的，而且本身也属于局部变量。但是，student指向的对象实例存放在heap，因为它的大小不确定。作为一条规则可以记住，所有的对象都存放在heap。
当main方法运行结束，整个stack被清空，name, age 和 student这三个变量消失，因为它们是局部变量，区块一旦运行结束，就没必要再存在了。而heap之中的那个对象实例继续存在，直到系统的垃圾清理机制将这块内存回收。因此，一般来说，内存泄漏都发生在heap，即某些内存空间不再被使用了，却因为种种原因，没有被系统回收。
