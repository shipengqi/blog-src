---
title: Nodejs webdriver.io
date: 2018-03-19 17:44:15
categories: ["NodeJs"]
tags: ["Automation test"]
---

[webdriver.io 官网](http://webdriver.io/)
[官方文档](http://webdriver.io/guide.html)

<!-- more -->

下文内容翻译自官方文档，水平有限，有能力还是看[官方文档](http://webdriver.io/guide.html)。

## Get Started

### 安装
``` bash
$ npm install webdriverio --save-dev

#校验是否安装成功
$ ./node_modules/.bin/wdio --help
```

也可以全局安装`wdio`，建议安装在项目目录下。
``` bash
$ npm install -g webdriverio --save-dev

#校验是否安装成功
$ wdio --help
```

#### 设置selenium环境
设置`selenium`环境的两种方法：
1. 分别安装`selenium server`和`browser driver`，获取最新的[selenium standalone server](http://docs.seleniumhq.org/download/)。
[chrome driver](https://sites.google.com/a/chromium.org/chromedriver/home)。
```bash
安装selenium server
java -jar /your/download/directory/selenium-server-standalone-3.5.3.jar

#
```
2. 最简单的方法是安装[`NPM selenium standalone package`](https://github.com/vvo/selenium-standalone)：

```bash
#全局安装
npm install selenium-standalone -g
#安装selenium server
selenium-standalone install
#启动firefox, chrome, internet explorer or phantomjs
selenium-standalone start
```

### 配置webdriverio实例

如果创建一个`WebdriverIO instance`,需要定义`options`设置适当的功能和设置。例如，当调用`remote`方法时：
```javascript
var webdriverio = require('webdriverio');
var options = {
    desiredCapabilities: {
    	platformName: 'android',                        // operating system
    	platformVersion:'4.3',                          // OS version
        browserName: 'chrome',                          // browser
        udid: 'asdfasdfasdf',                           // udid of the android device
		deviceName: 'devicexy',                         // device name
    },
    host: 'localhost',                                  // localhost
    port: 4723                                          // port for appium
};
var client = webdriverio.remote(options);
```

通过一个`options`对象定义`WebdriverIO instance`。

> 注意这只在你使用`standalone package`运行` WebdriverIO`时时必要的。
> 如果使用`wdio test runner`时，`options`配置在`wdio.conf.js`配置文件中。

#### `options`

##### desiredCapabilities

定义你所运行的`Selenium`会话的功能。

具体文档参考[Selenium documentation](https://github.com/SeleniumHQ/selenium/wiki/DesiredCapabilities)

类型：`Object`
默认值：`{ browserName: 'firefox' }`。

Example:

```javascript
browserName: 'chrome',    // options: `firefox`, `chrome`, `opera`, `safari`
version: '27.0',          // browser version
platform: 'XP',           // OS platform
tags: ['tag1','tag2'],    // specify some tags (e.g. if you use Sauce Labs)
name: 'my test'           // set name for test (e.g. if you use Sauce Labs)
pageLoadStrategy: 'eager' // strategy for page load
```

`pageLoadStrategy`在`selenium` [2.46.0](https://github.com/SeleniumHQ/selenium/blob/master/java/CHANGELOG#L494)实现,

只支持Firefox。有效的值：
`normal` - 等待`document.readyState`的值变为`complete`。默认值。
`eager` - 当`document.readyState`的值为`interactive`时将会放弃等待，而不是等待`document.readyState`的值变为`complete`。
`none` - 将立即中止等待,而不必等待任何页面的加载。


##### logLevel
日志级别。

类型：`String`
默认值：`silent`。
选项：verbose | silent | command | data | result

verbose: 记录所有日志。
silent: 不记录任何日志。
command: 记录`Selenium server` 的url访问日志。 (e.g. [15:28:00] COMMAND GET "/wd/hub/session/dddef9eb-82a9-4f6c-ab5e-e5934aecc32a/title")
data: 请求负载数据的日志 (e.g. [15:28:00] DATA {})
result: `Selenium server`返回结果日志。 (e.g. [15:28:00] RESULT "Google")

##### logOutput

`WebdriverIO`日志输出到文件。可以定义日志文件的路径，`WebdriverIO`会生成日志文件，者你可以传递一个可写流,日志会重定向到可写流。

可写流`wdio runner` 还不支持。

类型：`String | writeable stream`
默认值：null。

##### protocol

与`Selenium standalone server`或者(`driver`)通信时使用的协议。

类型：`String`
默认值：`http`。

##### host

`WebDriver server`的`host`。

类型：`String`
默认值：`127.0.0.1`。

##### port

`WebDriver server`的`port`。

类型：`Number`
默认值：`4444`。

##### path

`WebDriver server`的路径。

类型：`String`
默认值：`/wd/hub`。

##### baseUrl

设置一个`base url`。

类型：`String`
默认值：null。

##### connectionRetryTimeout

设置请求`Selenium server`超时重试时间。

类型：`Number`
默认值：90000。

##### connectionRetryCount

设置请求`Selenium server`超时重试次数。

类型：`Number`
默认值：3。

##### coloredLogs

开启日志输出的颜色。

类型：`Boolean`
默认值：`true`。


##### deprecationWarnings

警告当使用已弃用的命令时。

类型：`Boolean`
默认值：`true`。

##### bail

指定一个数量，运行测试时当没有通过的测试达到该数量时停止执行。注意,当使用一个第三方测试框架如`mocha`,可能需要额外的配置。

类型：`Number`
默认值：0。（运行所有`tests`，不停止执行）

##### screenshotPath

设置截图路径，用来保存`Selenium driver`崩溃的截图。

类型：`String | null`
默认值：null。

##### screenshotOnReject

如果`Selenium driver`崩溃，添加当前页面的截图附件到`error`，可以指定为`object`设置重试尝试截图超时时间和次数。

类型：`String | Object`
默认值：`false`。

> 添加当前页面的截图附件到`error`使用额外的时间去截图和额外的内存来存储它。所以为了性能它在默认情况下是禁用的。

Example:

```javascript
// take screenshot on reject
screenshotOnReject: true

// take screenshot on reject and set some options
screenshotOnReject: {
    connectionRetryTimeout: 30000,
    connectionRetryCount: 0
}
```

##### waitforTimeout

所有`waitForXXX`命令的默认超时时间。

类型：`Number`
默认值：1000。

##### waitforInterval

所有`waitForXXX`命令的默认循环时间间隔。

类型：`Number`
默认值：500。

##### queryParams

用来存储`query parameters`的键值对，将会被添加到每个`selenium`请求。

类型：`Object`
默认值：None。

Example:
```javascript
queryParams: {
  specialKey: 'd2ViZHJpdmVyaW8='
}

// Selenium request would look like:
// http://127.0.0.1:4444/v1/session/a4ef025c69524902b77af5339017fd44/window/current/size?specialKey=d2ViZHJpdmVyaW8%3D
}
```
##### headers

用来存储`headers`的键值对，将会被添加到每个`selenium`请求。值必须是字符串。

类型：`Object`
默认值：None。

Example:
```javascript
headers: {
  Authorization: 'Basic dGVzdEtleTp0ZXN0VmFsdWU='
}
// This adds headers based on the key
// This would result in a header named 'Authorization' with a value of 'Basic dGVzdEtleTp0ZXN0VmFsdWU='
```

##### debug

开始`node`调试。

类型：`Boolean`
默认值：`false`。

##### execArgv

指定`node`的参数当启动`child processes`时。

类型：`Array of String`
默认值：`null`。


#### 配置Babel

适用于`babel 6`。
**安装babel依赖**
``` bash
npm install --save-dev babel-register babel-preset-es2015
```

**mocha test**
使用mocha内部的编译器注册`babel`。
```javascript
mochaOpts: {
    ui: 'bdd',
    compilers: ['js:babel-register'],
    require: ['./test/helpers/common.js']
},
```

**配置.babelrc**
使用`webdriverio`时不建议使用`babel-polyfill`，使用`babel-runtime`代替。
```bash
npm install --save-dev babel-plugin-transform-runtime babel-runtime
```

`.babelrc`文件
```json
{
  "presets": ["es2015"],
  "plugins": [
    ["transform-runtime", {
      "polyfill": false
    }]
  ]
}
```

可以使用`babel-preset-es2015-nodeX`代替`babel-preset-es2015`,其中X是`Node`的版本,为了避免不必要的`polyfills`像`generators`:
```bash
npm install --save-dev babel-preset-es2015-node6
```

```json
{
  "presets": ["es2015-node6"],
  "plugins": [
    ["transform-runtime", {
      "polyfill": false,
      "regenerator": false
    }]
  ]
}
```

### boilerplate

**[saucelabs-sample-test-frameworks/JS-Mocha-WebdriverIO-Selenium](https://github.com/saucelabs-sample-test-frameworks/JS-Mocha-WebdriverIO-Selenium)**
Simple boilerplate project that runs multiple browser on [SauceLabs](https://saucelabs.com/) in parallel.

- Framework: Mocha
- Features:
    - Page Object usage
    - Integration with [SauceLabs](https://saucelabs.com/)

**[jonyet/webdriverio-boilerplate](https://github.com/jonyet/webdriverio-boilerplate)**
Designed to be quick to get you started without getting terribly complex, as well as to share examples of how one can leverage external node modules to work in conjunction with wdio specs.

- Framework: Mocha
- Features:
    - examples for using Visual Regression testing with WebdriverIO v4
    - cloud integration with [BrowserStack](https://www.browserstack.com/)
    - Page Objects usage

**[cognitom/webdriverio-examples](https://github.com/cognitom/webdriverio-examples)**
Project with various examples to setup WebdriverIO with an internal grid and PhantomJS or using cloud services like [TestingBot](https://testingbot.com/).

- Framework: Mocha
- Features:
    - examples for the tunneling feature from TestingBot
    - standalone examples
    - simple demonstration of how to integrate PhantomJS as a service so no that no Java is required

**[michaelguild13/Selenium-WebdriverIO-Mocha-Chai-Sinon-Boilerplate](https://github.com/michaelguild13/Selenium-WebdriverIO-Mocha-Chai-Sinon-Boilerplate)**
Enhance testing stack demonstration with Mocha and Chai allows you to write simple assertion using the [Chai](http://www.chaijs.com/) assertion library.

- Framework: Mocha
- Features:
    - Chai integration
    - Babel setup

**[WillLuce/WebdriverIO_Typescript](https://github.com/WillLuce/WebdriverIO_Typescript)**
This directory contains the WebdriverIO page object example written using TypeScript.

- Framework: Mocha
- Features:
    - examples of Page Object Model implementation
    - Intellisense

**[klamping/wdio-starter-kit](https://github.com/klamping/wdio-starter-kit)**
Boilerplate repo for quick set up of WebdriverIO test scripts with TravisCI, Sauce Labs and Visual Regression Testing

- Framework: Mocha, Chai
- Features:
    - Login & Registration Tests, with Page Objects
    - Mocha
    - Chai with expect global
    - Chai WebdriverIO
    - Sauce Labs integration
    - Visual Regression Tests
    - Local notifications
    - ESLint using Semistandard style
    - WebdriverIO tuned Gitignore file

### How to use (Standalone Mode Vs WDIO Testrunner)

`WebdriverIO`可用于各种目的。它实现了Webdriver 协议 API和可以自动运行浏览器。框架设计可以在任意工作环境和任何类型的任务。
它是独立于任何第三方框架，只需要运行`Nodejs`。

#### Standalone Mode
`Standalone Mode`是运行`WebdriverIO`的最简单的方法。和调用`selenium-server-standalone`的`Selenium server file`无关。
只需要`require('webdriverio')`在你的项目里，然后使用API运行你的automation。

```javascript
var webdriverio = require('webdriverio');
var options = { desiredCapabilities: { browserName: 'chrome' } };
var client = webdriverio.remote(options);

client
    .init()
    .url('https://duckduckgo.com/')
    .setValue('#search_form_input_homepage', 'WebdriverIO')
    .click('#search_button_homepage')
    .getTitle().then(function(title) {
        console.log('Title is: ' + title);
        // outputs: "Title is: WebdriverIO (Software) at DuckDuckGo"
    })
    .end();
```
`WebdriverIO`的`Standalone Mode`允许集成自动化工具在你自己的项目中去创建新的自动化库。
例如[Chimp](https://chimp.readme.io/)和[CodeceptJS](https://codecept.io/)。

#### The WDIO Testrunner
主要做大规模的e2e测试。因此,我们实现了一个帮助构建一个可靠的测试套件,更容易阅读和维护。
`test runner`负责处理通常会碰到的许多自动化库问题。它可以组织运行你的测试，使测试可以最大并发执行。
它还处理会话管理和提供了很多功能,帮助调试问题和发现测试中的错误。

```javascript
describe('DuckDuckGo search', function() {
    it('searches for WebdriverIO', function() {
        browser.url('https://duckduckgo.com/');
        browser.setValue('#search_form_input_homepage', 'WebdriverIO');
        browser.click('#search_button_homepage');

        var title = browser.getTitle();
        console.log('Title is: ' + title);
        // outputs: "Title is: WebdriverIO (Software) at DuckDuckGo"
    });
});
```
`wdio test runner`使测试框架的抽象例如： `Mocha， Jasmine ， Cucumber`。
不同于使用`Standalone Mode`，`wdio test runner`执行的所有命令是同步的。这意味着你不再用`Promise`来处理异步代码。
使用`wdio test runner`查看文档**[Getting Started](http://webdriver.io/guide/testrunner/gettingstarted.html)**

## Usage


## Testrunner
## Reporter
## Services
## Plugins
## Examples