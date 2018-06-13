---
title: Nodejs 单元测试
date: 2018-03-19 17:44:00
categories: ["NodeJs"]
tags: ["Automation test"]
---

https://www.liaoxuefeng.com/wiki/001434446689867b27157e896e74d51a89c25cc8b43bdb3000/00147203593334596b366f3fe0b409fbc30ad81a0a91c4a000
https://www.jianshu.com/p/9c78548caffa
https://istanbul.js.org/docs/tutorials/

issues:
Resolution method is overspecified --> https://mochajs.org/
cannot exit -->   add option --exit

--compilers
CoffeeScript不再被直接支持。这类预编译语言可以使用相应的编译器扩展来使用，比如CS1.6：--compilers coffee:coffee-script 和CS1.7+：--compilers coffee:coffee-script/register

babel-register
如果你的ES6模块是以.js为扩展名的，你可以npm install --save-dev babel-register，然后--require babel-register; --compilers就可以指定文件扩展名
