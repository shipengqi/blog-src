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

### 令牌内检

令牌内检的意思就是，**受保护资源服务**要验证**授权服务颁发的令牌**，受保护资源服务调用授权服务的接口来检验令牌。

### JWT 如何使用

授权服务颁发 JWT token 给第三方软件，第三方软件拿着 token 来请求受保护资源。JWT 在公网上传输，用 base64 进行编码，同时还需要进行签名及加密处理。

### JWT 的优缺点

优点：

1. JWT 的核心思想就是用计算替代存储，就是时间换空间。
2. 加密。
3. JWT token，有助于增强系统的可用性和可伸缩性。为什么这么说，因为 JWT token 本身包含了验证身份需要的信息，不需要服务端额外的存储，每次请求都是
   无状态的。
   
缺点：

1. JWT token 不会在服务端存储，所以无法改变 token 的状态。这就意味着，只要 token 没有过期，就可以一直使用。

为了解决这个问题，通 常会有两种做法：

1. 将每次生成 JWT 令牌时的秘钥粒度缩小到用户级别，也就是一个用户一个秘钥。这样，当用户取消授权或者修改密码后，就可以让这个密钥一起修改。一般情况下，这
   种方案需要配套一个单独的密钥管理服务。
2. 在不提供用户主动取消授权的环境里面，如果只考虑到修改密码的情况，那么就可以把用户密码作为 JWT 的密钥。当然，这也是用户粒度级别的。这样一来，用户
   修改密码也就相当于修改了密钥。


### Token 生命周期

无论是JWT 结构化令牌还是普通的令牌。它们都有有效期，只不过，JWT 令牌可以把有效期的信息存储在本身的结构体中。

OAuth 2.0 的令牌生命周期，通常会有三种情况：

1. 自然过期，这是最常见的情况。这个过程是，从授权服务创建 一个令牌开始，到第三方软件使用令牌，再到受保护资源服务验证令牌，最后再到令牌失
   效。同时，这个过程也不排除主动销毁令牌的事情发生，比如令牌被泄露，授权服务可以 做主让令牌失效。
2. 访问令牌失效之后可以使用刷新令牌请求 新的访问令牌来代替失效的访问令牌，以提升用户使用第三方软件的体验。
3. 就是让第三方软件比如小兔，主动发起令牌失效的请求，然后授 权服务收到请求之后让令牌立即失效。

## 第三方软件

如何构建第三方软件，

包括 4 部分，分别是：**注册信息、引导授权、使用访问令牌、使用刷新令牌**。

### 注册信息

小兔软件只有先有了身份，才可以参与到 OAuth 2.0 的流程中去。也就是说，小兔软件需要先拥有自己的 `app_id` 和 `app_serect` 等信息，同时还要填写
自己的回调地址 `redirect_uri`、申请权限等信息。这也叫做**静态注册**，

### 引导授权
当用户需要使用第三方软件，来操作其在受保护资源上的数据，就需要第三方软件来引导 授权。小兔软件需要小明的授权，只有授权服务才能允许小明这样做。所以呢，小兔软
件需要“配合”小明做的第一件事儿，就是将小明引导至授权服务。让用户为第三方软件授权，得到了授权之后，第三方软件才可以 代表用户去访问数据。

### 使用 `access_token`

**拿到令牌后去使用令牌，才是第三方软件的最终目的**。

目前 OAuth 2.0 的令牌只支持一种类型，那就是 `bearer` 令牌，可以是任意字符串格式的令牌。使用 `access_token`请求的方式，有三种：

1. URI Query Parameter：
```
GET /resource?access_token=b1a64d5c-5e0c-4a70-9711-7af6568a61fb HTTP/1.1
```

2. POST 表单：
```
POST /resource HTTP/1.1
Host: server.example.com
Content-Type: application/x-www-form-urlencoded

access_token=b1a64d5c-5e0c-4a70-9711-7af6568a61fb
```

3. Authorization Request Header：
```
GET /resource HTTP/1.1
Host: server.example.com
Authorization: Bearer b1a64d5c-5e0c-4a70-9711-7af6568a61fb
```

建议是采用 Authorization 的方式来传递令牌。


使用 `refresh_token` 的方式跟使用 `access_token` 是一样的。

`refresh_token`的使用，最需要关心的是，什么时候使用 `refresh_token`？

例如，在小兔打单软件收到 `access_token` 的同时，也会收到 `access_token` 的过期时间 `expires_in`。一个设 计良好的第三方应用，应该将 
`expires_in` 值保存下来并定时检测；如果发现 `expires_in`即将过期，则需要利用 `refresh_token` 去重新请求授权服务，以便获取新的、有效的访问
令牌。

这种定时检测的方法可以提前发现 `access_token` 是否即将过期。此外，还有一种方法是“现场”发现。也就是说，比如小兔软件访问小明店铺订单的时候，
突然收到一个 `access_token` 失 效的响应，此时小兔软件立即使用 `refresh_token` 来请求一个 `access_token`，以便继续代表小 明使用他的数据。

> `refresh_token` 是一次性的，使用之后就会失效，但是它的有效期会比 `access_token` 要长。但是如果 `refresh_token` 也过期了怎么办？
在这种情况下，就需要重新授权了。

## 资源拥有者凭据许可（Password）

资源拥有者的凭据，就是用户名和密码。这是最糟糕的一种方式。为什么 OAuth 2.0 还支持这种许可类型？

例如，小兔此时就是京东官方出品的一款软件，小明也是京东的用户，那么小明其实是可以使用用户名和密码来直接使用小兔这款软件的。原因很简单，那就是这里不再
有“第三方”的概念了。

小兔软件只需要使用一次用户名和密码数据来换回一个 token，进而通过 token 来访问小明店铺的数据，以后就不会再使用用户名和密码了。

![password-flow](/images/oauth2.0/password-flow.png)

> 注意第 2 步中的 `grant_type` 的值为 `password`，告诉授权服务使用资源拥有者凭据许可凭据的方式去请求访问。

## 客户端凭据许可（Client Credentials）

如果小兔软件访问了一个不需要用户小明授权的数据，比如获取京东 LOGO 的图片地址，这个 LOGO 信息不属于任何一个第三方用户。在授权流程中，就不再需要
资源拥有者这个角色了。也可以理解为“第三方软件就是资源拥有者”。

这种场景下的授权，便是客户端凭据许可，第三方软件可以直接使用注册时的 `app_id` 和 `app_secret` 来换回访问令牌 token。

![client-credential-flow](/images/oauth2.0/client-credential-flow.png)

> 第 1 步：第三方软件小兔通过后端服务向授权服务发送请求，这里 `grant_type` 的值为 `client_credentials`

## 隐式许可（Implicit）

如果小明使用的小兔打单软件应用没有后端服务，就是在浏览器里面执行的，比如纯粹的 JavaScript 应用，应该如何使用 OAuth 2.0？

在这种情况下，小兔软件对于浏览器就没有任何保密的数据可以隐藏了，不需要 `app_secret` 的值，也不用再通过授权码 code。因为使用授权码的目的之一，
就是把浏览器和第三方软件的信息做一个隔离，确保浏览器看不到 access_token。

![implicit-flow](/images/oauth2.0/implicit-flow.png)

**隐式许可授权流程的安全性会降低很多**。

## OIDC

OIDC 是一种用户身份认证的开放标准。OIDC 是基于 OAuth 2.0 构建的身份认证框架协议。OAuth 2.0 是一种授权协议，而不是身份认证协议。

**OIDC = 授权协议 + 身份认证**，是 OAuth 2.0 的超集。

OIDC 和 OAuth 2.0 的角色对应关系：

![oidc-roles](/images/oauth2.0/oidc-roles.png)

OIDC 标准框架中的三个角色：

- EU（End User），终端用户
- RP（Relying Party），认证服务的依赖方，就是 OAuth 2.0 中的第三方软件。
- OP（OpenID Provider），身份认证服务提供方

OIDC 的通信流程：

![oidc-flow](/images/oauth2.0/oidc-flow.png)

OIDC 的授权码流程和 OAuth 2.0 授权码流程几乎一样，唯一的区别就是多了一个 `ID_TOKEN`。

### ID_TOKEN

OIDC 对 OAuth 2.0 最主要的扩展就是提供了 `id_token`。

`id_token` 和 `access_token` 是一起返回的。但是 `access_token` 是不需要被第三方软件解析的。而 `id_token` 需要被第三方软件解析，从而获取
`id_token` 中的信息。

`id_token` 能够标识用户，失效时间等属性来达到身份认证的目的。`id_token` 才是身份认证得关键。

#### ID_TOKEN 中有什么信息？

`id_token` 也是 JWT token（由一组 Cliams 构成以及其他辅助的 Cliams），一定包含下面 5 个参数：

- iss，token 的颁发者，它的值就是 OP 的 URL。
- sub，token 的主题，值是一个代表 EU 的全局唯一的标识符。
- aud，token 的目标受众，值是 RP 的 `app_id`。
- exp，token 的过期时间。
- iat，token 的颁发时间。

在第三方软件（RP）拿到这些信息之后，就获得了身份信息（如 sub，EU 的全局唯一的标识符），然后对身份信息进行验证 至此，可以说用户身份认证就可以完成了，
后续可以根据 UserInfo EndPoint 获取更完整的信息。

### OIDC 流程

**`id_token` -> 创建 UserInfo EndPoint -> 解析 `id_token` -> 记录登录状态 -> 获取 UserInfo**。