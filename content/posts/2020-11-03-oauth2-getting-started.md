---
title: OAuth 2.0 Getting Started
date: 2020-11-03T13:48:12+08:00
categories: ["Others"]
draft: false
---

OAuth 2.0 是一种授权协议。

## OAuth 2.0 有什么用？

OAuth 2.0 就是保证第三方（软件）只有在获得授权之后，才能进一步访问授权者的数据。

OAuth 2.0 的体系里面有 4 种角色，分别是：

- 资源拥有者
- 客户端
- 授权服务
- 受保护资源

## OAuth 2.0 的 4 种授权类型

- 授权码许可（Authorization Code），通过授权码 code 获取 `access_Token`
- 客户端凭据许可（Client Credentials），通过第三方 client 的 `app_id` 和 `app_secret` 获取 `access_Token`
- 资源拥有者凭据许可（Password），通过用户的 username 和 password 获取 `access_Token`
- 隐式许可（Implicit），通过嵌入在浏览器的第三方 client 的 `app_id` 获取 `access_Token` 


### 授权码许可类型

下图就是授权码许可的流程：

![auth-code-flow](/images/oauth2.0/auth-code-flow.png)

上面的流程第 4 步，授权服务生成了授权码 code，然后重定向到了 client。经历了两次重定向，为什么不直接返回 `access_token`？

> 原因是如果直接返回 `access_token`，就不能使用重定向的方式，`access_token` 在 URL 中**会把 `access_token` 暴露在浏览器上**，有被窃取的安全风险。

下面是没有授权码的流程：

![auth-code-flow-without-code](/images/oauth2.0/auth-code-flow-without-code.png)

> 由于少了一次重定向，浏览器停在了授权页面上，无法回到小兔软件的页面。

这就是授权码这个间接凭证的作用。

## 授权服务

授权服务就是负责颁发访问令牌的的服务。OAuth 2.0 的核心就是授权服务，授权服务的核心是令牌。

### 授权服务要做些什么

例如小兔软件要让小明去京东商家开放平台那里给它授权数据，那这里总不能你要，京东开放平台就给你。需要小兔先去平台上注册，注册完以后，平台会给小兔软件 `app_id` 和 `app_secret`
等信息，方便之后的授权验证。

同时，注册的时候，还要配置受保护资源的可访问范围。比如小兔软件能否获取小明店铺的订单信息，能否获取订单的所有字段信息等，这个权限范围就是 **scope**。

注册完之后，授权服务的授权码许可流程：

![auth-server-work-flow](/images/oauth2.0/auth-server-work-flow.png)

### 授权码许可流程

包含两部分：**准备工作**和**生成授权码 code**。

准备工作：

1. 验证基本信息包括对第三方软件合法性和回调地址合法性的校验。
   - 在浏览器环境下，颁发 code 的请求过程都是在浏览器前段完成的，意味着有被冒充的风险。因为授权服务 必须对第三方软件的存在性做判断。
   - 回调地址也是可以被伪造的。因此也需要校验是否是已经注册的回调地址。
2. 校验权限范围，比如使用微信登录第三方软件时，微信授权页面会提示第三方软件会获得你的昵称，头像，地理位置等信息。如果不想让第三方获取，可以不选择
   某一项。这就是说需要对小兔软件传过来的 scope 参数，与小兔软件在平台注册时申请的 scope 对比校验。
3. 生成授权页面，用户点击 **approve** 之后叫（这之前还会有登录操作），才会生成授权码 code 和 `access_token`。

生成授权码 code：
1. 第二次校验权限范围，使用用户授权之后的权限 scope 和注册时的 scope 做比对。因为用户点击 approve 之前可以选择权限范围。
2. 处理请求，生成授权码 code。校验 `response_type`，有两种类型的值 `code` 和 `token`，授权码流程的 `response_type` 的值就是 code。
   授权服务将 code 与 `app_id` 和 user 进行关系映射，由于授权码 code 是临时的，所以还需要设置有效期（一般不会超过 5 分钟），并且**一个授权码 code 只能被使用一次**。
   **将授权码 code 和 scope 绑定存储**，后续颁发 `access_token` 时通过 code 获取 scope，并与 `access_token` 绑定。
3. 重定向到第三方软件，code 在重定向 URL 种。
   
颁发访问令牌：
1. 小兔软件拿着 code 来请求，这个过程在后端完成，校验 `grant_type` 是否为 `authorization_code`，校验 `app_id` 和 `app_secret`。
2. 校验授权码 code 是否合法，取出之前存储的 code，**code 值对应的 key 是 `app_id` 和 user 的组合值。确认 code 有效后，从存储中删除**。
3. 生成 `access_token`，有三个原则：**唯一性，不连续性，不可猜性**。存储 `access_token` ，并与 `app_id` 和 user 进行关系映射。还需要和 scope 绑定，设置过期时间 `expires_in`。

### refresh_token

颁发 `refresh_token` 和 `access_token` 是一起生成的。第三方软件会得到两个 token。

`refresh_token` 有什么用？

在 `access_token` 失效的情况 下，为了不让用户频繁手动授权，通过 `refresh_token` 向系统重新请求生成一个新的 `access_token`。

在 OAuth 2.0 规范中，`refresh_token` 是一种特殊的授权许可类型，是嵌入在授权码许可类型下的一种特殊许可类型。

`refresh_token` 流程主要包括如下两大步骤：

1. `grant_type` 值为 `refresh_token`，验证第三方软件是否存在，验证 `refresh_token`。验证 `refresh_token` 是否属于该第三方软件。
2. 重新生成 `access_token` 和 `refresh_token`。

> 一个 `refresh_token` 被使用以后，授权服务需要将其废弃，并重新颁发一个 `refresh_token`。

## JWT

JSON Web Token（JWT）是一个开放标准，就是用一种结构化封装的方式生成 token 的技术。

结构化后，token 本身就可以包含一些有用的信息，可以分为三部分：

- Header，typ 表示 token 的类型，alg 表示使用的签名算法
- Payload，JWT 的数据体。sub 一般为资源拥有者的唯一标识，exp token 的过期时间，iat token 的颁发时间。还可以自定义声明。
- Signature，JWT 信息的签名。防止信息被篡改。

三部分通过 `.` 分隔，`Header.Payload.Signature`。

