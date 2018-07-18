---
title: ESlint使用
date: 2017-11-03 15:23:07
categories: ["Javascript"]
tags: ["ESlint"]
---

ESLint 是JavaScript的代码检查工具，使用它可以避免低级错误和统一代码的风格。ESlint 被设计为是完全可配置的，这意味着你可以关闭每一个规则，只运行基本语法验证，或混合和匹配绑定的规则和自定义规则，以让 ESLint 更适合于你的项目。
[**ESLint中文文档**](http://eslint.cn/)

<!-- more -->

## 使用
### 安装

``` bash
npm install -g eslint

#生成配置文件
eslint --init
```

`eslint --init`适用于对某个项目进行设置和配置 ESLint，并在其运行的的目录执行本地安装的 ESLint 及 插件。如果你倾向于使用全局安装的 ESLint，你配置中使用的任何插件也必须是全局安装的。
运行 `eslint --init` 之后，`.eslintrc` 文件会在你的文件夹中自动创建。

### 配置ESlint

配置ESlint有种方式，常用的两种方式：

- 添加 `.eslintrc.json`文件，放在项目根目录，也可以是`.eslintrc.yml`，`.eslintrc.js`，`.eslintrc`。
- 在`package.json`文件中添加`eslintConfig`属性，所有的配置包含在此属性中。

优先级顺序：`.eslintrc.js` > `.eslintrc.yaml` > `.eslintrc.yml` > `.eslintrc.json` > `.eslintrc` > `package.json`。

## 配置规则

### 配置环境
``` json

"env": {
	"es6": true,
	"browser": true,
	"node": true,
	"mocha": true
},

```
### 配置全局变量
``` json

"globals": {
	"var1": true,
	"var2": true,
	"var3": false
},

```
`true`代表允许重写、`false`代表不允许重写。


### 配置Rules

规则的等级有三种：

`off` 或者 0：关闭规则。
`warn` 或者 1：打开规则，并且作为一个警告（不影响exit code）。
`error` 或者 2：打开规则，并且作为一个错误（exit code将会是1）。

例如：

``` json

"rules": {
	"eqeqeq": "off",
	"curly": "off"
},

```

所有的规则默认都是禁用的。在配置文件中，使用 "extends": "eslint:recommended" 将会默认开启所有在[ESLint规则页面](http://eslint.cn/docs/rules/)被标记为 *绿色对钩图标* 的规则。

在[ESLint规则页面](http://eslint.cn/docs/rules/)，规则的旁边带有一个*橙色扳手图标*，表示在执行eslint命令时指定--fix参数可以自动修复该问题。

可以在 `npm` 搜索 “eslint-config” 使用别人创建好的配置。只有在你的配置文件中扩展了一个可分享的配置或者明确开启一个规则，ESLint 才会去校验你的代码。


## 高级配置

ESLint 允许你指定你想要支持的 JavaScript 语言选项。默认情况下，ESLint 支持 ECMAScript 5 语法。可以覆盖该设置启用对 ECMAScript 其它版本和 JSX 的支持。

请注意，对 JSX 语法的支持不用于对 React 的支持。React 适用于特定 ESLint 无法识别的 JSX 语法。如果你正在使用 React 和 想要 React 语义，推荐用 [eslint-plugin-react](https://github.com/yannickcr/eslint-plugin-react)。

同样的，支持 ES6 语法并不意味着支持新的 ESLint 全局变量或类型（如，新类型比如 Set）。对于 ES6 语法，使用 `{ "parserOptions": { "ecmaVersion": 6 } }`；对于新的 ES6 全局变量，使用 `{ "env":{ "es6": true } }`(这个设置会自动启用 ES6 语法)。

在 `.eslintrc.*` 文件使用 `parserOptions` 属性设置解析器选项。可用的选项有：

- `ecmaVersion` - 设置为 3， 5 (默认)， 6、7 或 8 指定你想要使用的 ECMAScript 版本。你也可以指定为 2015（同 6），2016（同 7），或 2017（同 8）使用年份命名
- `ourceType` - 设置为 "script" (默认) 或 "module"（如果你的代码是 ECMAScript 模块)。
- `ecmaFeatures` - 这是个对象，表示你想使用的额外的语言特性:
- `globalReturn` - 允许在全局作用域下使用 `return` 语句
- `impliedStrict` - 启用全局 `strict mode` (如果 ecmaVersion 是 5 或更高)
- `jsx` - 启用 JSX
- `experimentalObjectRestSpread `- 启用对实验性的 `object rest/spread properties` 的支持。(重要：这是一个实验性的功能,在未来可能会改变明显。 建议你写的规则 不要依赖该功能，除非当它发生改变时你愿意承担维护成本。)

更多详细配置[*Configuring ESLint*](http://eslint.cn/docs/user-guide/configuring)

## 集成webstrom

打开webstorm，选择`File | Settings | Languages & Frameworks | JavaScript | Code Quality Tools | ESLint` 勾选 `Enable` 。
webstorm可以自动提示 eslint指出的代码问题。

## 使用现有的通用规则
`eslint`官方提供了3种预安装包：

### eslint-config-google

`Google`标准

执行安装：
``` bash
npm install eslint eslint-config-google -g
```

### eslint-config-airbnb

`Airbnb`标准,它依赖`eslint`, `eslint-plugin-import`, `eslint-plugin-react`, and `eslint-plugin-jsx-a11y`等插件，并且对各个插件的版本有所要求。

你可以执行以下命令查看所依赖的各个版本：
``` bash
npm info "eslint-config-airbnb@latest" peerDependencies
```
你会看到以下输出信息，包含每个了每个`plugins`的版本要求
``` bash
{ eslint: '^3.15.0',
  'eslint-plugin-jsx-a11y': '^3.0.2 || ^4.0.0',
  'eslint-plugin-import': '^2.2.0',
  'eslint-plugin-react': '^6.9.0' }
```  
知道了每个`plugins`的版本要求后，代入以下命令执行安装即可使用：
``` bash
npm install eslint-config-airbnb eslint@^#.#.# eslint-plugin-jsx-a11y@^#.#.# eslint-plugin-import@^#.#.# eslint-plugin-react@^#.#.# -g
```

### eslint-config-standard

`Standard`标准，它是一些前端工程师自定的标准。

执行安装：
``` bash
npm install eslint-config-standard eslint-plugin-standard eslint-plugin-promise -g
```
目前来看，公认的最好的标准是`Airbnb`标准。建议全局安装这些标准，然后在你的`.eslintrc`配置文件中直接使用：
``` json
{
  "extends": "google"
  //"extends": "airbnb"
  //"extends": "standard"
}
```

### eslint-config-sactive
[eslint-config-sactive](https://github.com/sactive/eslint-config-sactive)，是我基于`Standard`标准，封装的自己的代码风格的包。

