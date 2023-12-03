---
title: VS code 配置 Golang 远程开发
date: 2020-11-11T13:14:12+08:00
categories: ["Go"]
draft: false
---

首先要安装扩展 [Remote SSH](https://code.visualstudio.com/docs/remote/ssh)，另外你的服务器需要支持 SSH 连接。

打开 VS Code，点击左下角的 "Open a Remote Window"，选择 "Connect to Host"。

点击 "Add New SSH Host" 配置你的远程机器，或者选择已经配置好的 Hosts。

也可以 `Crtl+shift+p` 打开 commands，输入 "Open SSH Configuration File" 直接编辑配置文件：

```
# Read more about SSH config files: https://linux.die.net/man/5/ssh_config
Host shcCDFrh75vm8.hpeswlab.net
    HostName shcCDFrh75vm8.hpeswlab.net
    Port 22
    User root

Host shccdfrh75vm7.hpeswlab.net
    HostName shccdfrh75vm7.hpeswlab.net
    User root
```

配置好之后，连接 host，选择 platform：Linux, Windows, macOS。然后输入密码连接，建立连接之后，点击 "Open Folder" 就可以打开你远程机器上的代码目录了。

VS Code 会提示远程机器需要安装 Go 扩展，选择安装。

## 免密登陆

生成本机的秘钥对 `ssh-keygen -t rsa`，输入 "Open SSH Configuration File" 编辑配置文件：

```
Host shccdfrh75vm7.hpeswlab.net
    HostName shccdfrh75vm7.hpeswlab.net
    User root
    IdentityFile <absolute-path>/.ssh/id_rsa
```

将 SSH 公钥添加到远程机器：

```
ssh-copy-id username@remote-host
```

如果 `ssh-copy-id` 不存在，就手动将 `<absolute-path>/.ssh/id_rsa.pub` 的内容，添加到远程机器的 `~/.ssh/authorized_keys` 文件后面。

## 调试

远程调试 Golang，本地机器和远程机器都需要[安装 "dlv"](https://github.com/derekparker/delve/blob/master/Documentation/installation/README.md)。

点击侧边栏中的 "Run and Debug"，点击 "create a launch.json file" 会在 `.vscode` 目录下创建一个运行配置文件 `launch.json`。

下面是一个调试 Go 代码的 `launch.json` 的示例：
```json
{
  // Use IntelliSense to learn about possible attributes.
  // Hover to view descriptions of existing attributes.
  // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug helm list -A",
      "type": "go",
      "request": "launch",
      "mode": "auto",
      "program": "${workspaceFolder}/cmd/helm",
      "args": ["list", "-A"],
      "env": {
        "HELM_DRIVER": "configmap"
      }
    },
    {
      "name": "Launch test function",
      "type": "go",
      "request": "launch",
      "mode": "test",
      "program": "${workspaceFolder}",
      "args": [
        "-test.run",
        "MyTestFunction"
      ]
    },
    {
      "name": "Launch executable",
      "type": "go",
      "request": "launch",
      "mode": "exec",
      "program": "absolute-path-to-the-executable"
    },
    {
      "name": "Launch test package",
      "type": "go",
      "request": "launch",
      "mode": "test",
      "program": "${workspaceFolder}"
    },
    {
      "name": "Attach to local process",
      "type": "go",
      "request": "attach",
      "mode": "local",
      "processId": 12784
    }
  ]
}
```

常用的属性：
- `type`：调试器类型。`node` 用于内置的 Node 调试器，`php` 和 `go` 用于 PHP 和 Go 扩展。
- `request`：值可以是 `launch`，`attach`。当需要对一个已经运行的的程序 debug 时才使用 `attach`，其他时候使用 `launch`
- `mode`：值可以是 `auto`，`debug`，`remote`，`test`，`exec`。 对于 `attach` 只有 `local`，`remote`
- `program`：启动调试器时要运行的可执行文件或文件
- `args`： 传递给调试程序的参数
- `env`：环境变量（空值可用于 "取消定义 "变量），`env` 中的值会覆盖 `envFile` 中的值
- `envFile`：包含环境变量的 dotenv 文件的路径
- `cwd`：当前工作目录，用于查找依赖文件和其他文件
- `port`：连接到运行进程时的端口
- `stopOnEntry`：程序启动时立即中断
- `console`：使用哪种控制台，例如内部控制台、集成终端或外部终端
- `showLog`：是否在调试控制台打印日志, 一般为 `true`
- `buildFlags`：构建程序时需要传递给 Go 编译器的 Flags，例如 `-tags=your_tag`
- `remotePath`：`mode` 为 `remote` 时, 需要指定调试文件所在服务器的绝对路径
- `processId`：进程 id
- `host`：目标服务器地址
- `port`：目标端口

常用的变量：

- `${workspaceFolder}` 在工作区的的根目录调试程序
- `${file}` 调试当前文件
- `${fileDirname}` 调试当前文件所属的程序包

更多的属性和变量可以查看 [VS Code Debugging 文档](https://code.visualstudio.com/docs/editor/debugging)

### 远程调试

如果是远程启动程序，并调试，比较简单的方式，就是在远程开发的模式下，创建 `launch.json`，然后运行指定的配置进行断点调试。

也可以在本地的开发环境，进行远程调试，有两种方式，一种是调试已经运行的程序，一种是远程启动程序再调试。这两种都需要在远程服务器上启动 delve 服务：

第一种方式：

[编译源码并开启调试模式](https://shipengqi.github.io/posts/2020-04-09-go-remote-debug/#%E7%BC%96%E8%AF%91%E6%BA%90%E7%A0%81%E5%B9%B6%E5%BC%80%E5%90%AF%E8%B0%83%E8%AF%95%E6%A8%A1%E5%BC%8F)

第二种方式：
```
# 启动 delve 服务
$ dlv debug --headless --listen=:2345 --log --api-version=2
```

在 VS Code launch.json 中创建一个远程调试的运行配置：

```json
{
    "name": "Launch remote", 
    "type": "go",
    "request": "launch",
    "mode": "remote",
    "remotePath": "/absolute/path/to/remote/workspace/cmd/app",
    "host": "shcCDFrh75vm8.hpeswlab.net",
    "port": 22,
    "program": "/absolute/path/to/local/workspace/cmd/app",
    "env": {}
}

```

- `remotePath` 应该指向远程机器上调试文件的绝对路径 (在源代码中)
- `program` 指向本地机器上文件的绝对路径,此路径与 `remotePath` 对应。

## SSH File Bad Owner or Permission

检查一下你安装 VS Code 是不是使用的 "User Installer"，如果是，换成 "System Installer" 试一下。

如果还是没解决，参考 Troubleshooting guide [Fixing SSH file permission error](https://github.com/microsoft/vscode-docs/blob/main/docs/remote/troubleshooting.md#fixing-ssh-file-permission-errors)。



https://code.visualstudio.com/docs/editor/debugging#_launchjson-attributes