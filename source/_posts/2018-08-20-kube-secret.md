---
title: Kubernetes 资源 Secret
date: 2018-08-20 10:55:16
categories: ["Linux"]
tags: ["Kubernetes"]
---

我们知道 [ConfigMap](/2018/08/13/kube-configmap/) 是`Kubernetes`中的一种用来**存储配置**的资源对象。
但是对于密码、token、密钥等敏感信息，尽量不要使用`ConfigMap`，使用`Kubernetes`中的`Secret`来存储，降低暴露的风险。

<!-- more -->


## Secret 三种类型
- `Opaque`：`base64`编码格式的`Secret`，存储密码、密钥等敏感信息。
- `kubernetes.io/dockerconfigjson`：存储私有`docker registry`的认证信息。
- `Service Account`：用来访问`Kubernetes API`，由`Kubernetes`自动创建，并且会自动挂载到`Pod`的`/run/secrets/kubernetes.io/serviceaccount`目录。

## Opaque Secret
`Opaque`类型的数据是一个`map`类型，`value`必须是`base64`编码格式：
```bash
$ echo -n "admin" | base64
YWRtaW4=
$ echo -n "Admin@111" | base64
QWRtaW5AMTEx
```

test-secret.yml：
```yml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  username: YWRtaW4=
  password: QWRtaW5AMTEx
```

### 使用`yml`文件创建
创建`Secret`：
```bash
kubectl create -f test-secret.yml
```

### 使用`create secret generic`命令创建
根据配置文件、目录或指定的`key/value`创建`secret`。
```bash
kubectl create secret generic NAME [--type=string] [--from-file=[key=]source] [--from-literal=key1=value1] [--dry-run]
```

用法与[`create configmap`](/2018/08/13/kube-configmap/)类似。

创建`secret`：
```bash
# 创建保存 username 和 password 的文件
echo -n "admin" > ./username.txt
echo -n "Admin@111" > ./password.txt

# 创建
kubectl create secret generic my-secret --from-file=./username.txt --from-file=./password.txt
secret "db-user-pass" created
```
查看`secret`：
```bash
kubectl get secrets
NAME                  TYPE                                  DATA      AGE
my-secret          Opaque                                2         51s

kubectl describe secrets/my-secret
Name:            my-secret
Namespace:       default
Labels:          <none>
Annotations:     <none>

Type:            Opaque

Data
====
password.txt:    12 bytes
username.txt:    5 bytes
```
不论使用`get`还是`describe`命令默认都是不会显示文件的内容。为了防止将`secret`中的内容在终端日志记录中被暴露。

### Opaque Secret 使用
#### Secret 挂载到 Volume 中
```yml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: db
  name: db
spec:
  containers:
  - image: gcr.io/my_project_id/pg:v1
    name: db
    volumeMounts:
    - name: secrets
      mountPath: "/etc/secrets"
      readOnly: true
    ports:
    - name: cp
      containerPort: 5432
      hostPort: 5432
  volumes:
  - name: secrets
    secret:
      secretName: my-secret
```

进入`Pod`，查看挂载的信息：
```bash
# ls /etc/secrets
password  username
# cat  /etc/secrets/username
admin
# cat  /etc/secrets/password
Admin@111
```

#### Secret 设置环境变量
```yml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: wordpress-deployment
spec:
  replicas: 1
  strategy:
      type: RollingUpdate
  template:
    metadata:
      labels:
        app: wordpress
        visualize: "true"
    spec:
      containers:
      - name: "wordpress"
        image: "wordpress"
        ports:
        - containerPort: 80
        env:
        - name: WORDPRESS_DB_USER
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: username
        - name: WORDPRESS_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysecret
              key: password
```

#### 挂载指定`key`到指定路径
```yml
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: db
  name: db
spec:
  containers:
  - image: nginx
    name: db
    volumeMounts:
    - name: secrets
      mountPath: "/etc/secrets"
      readOnly: true
    ports:
    - name: cp
      containerPort: 80
      hostPort: 5432
  volumes:
  - name: secrets
    secret:
      secretName: my-secret
      items:
      - key: password
        mode: 511
        path: tst/psd
      - key: username
        mode: 511
        path: tst/usr
```

#### 挂载的 secret 被自动更新

当在`volume`中的`secret`被更新时，被映射的`key`也将被更新。

`Kubelet`在周期性同步时检查被挂载的`secret`是不是最新的。但是，它正在使用其基于本地`ttl`的缓存来获取当前的`secret`值。
结果是，当`secret`被更新的时刻到将新的`secret`映射到`pod`的时刻的总延迟可以与`kubelet`中的`secret`缓存的`kubelet sync period + ttl`一样长。

## `kubernetes.io/dockerconfigjson`
用`create secret docker-registry`命令创建用于`docker registry`认证的`secret`：

```bash
kubectl create secret docker-registry myregistrykey --docker-server=DOCKER_REGISTRY_SERVER --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
```

创建`Pod`的时候，通过`imagePullSecrets`引用刚创建的`myregistrykey`:
```yml
apiVersion: v1
kind: Pod
metadata:
  name: foo
spec:
  containers:
    - name: foo
      image: janedoe/awesomeapp:v1
  imagePullSecrets:
    - name: myregistrykey
```

查看`secret`：
```bash
kubectl get secret myregistrykey  -o yaml


apiVersion: v1
data:
  .dockercfg: eyJjY3IuY2NzLnRlbmNlbnR5dW4uY29tL3RlbmNlbnR5dW4iOnsidXNlcm5hbWUiOiIzMzIxMzM3OTk0IiwicGFzc3dvcmQiOiIxMjM0NTYuY29tIiwiZW1haWwiOiIzMzIxMzM3OTk0QHFxLmNvbSIsImF1dGgiOiJNek15TVRNek56azVORG94TWpNME5UWXVZMjl0In19
kind: Secret
metadata:
  creationTimestamp: 2017-08-04T02:06:05Z
  name: myregistrykey
  namespace: default
  resourceVersion: "1374279324"
  selfLink: /api/v1/namespaces/default/secrets/myregistrykey
  uid: 78f6a423-78b9-11e7-a70a-525400bc11f0
type: kubernetes.io/dockercfg
```
解码：
```bash
echo "eyJjY3IuY2NzLnRlbmNlbnR5dW4uY29tL3RlbmNlbnR5dW4iOnsidXNlcm5hbWUiOiIzMzIxMzM3OTk0IiwicGFzc3dvcmQiOiIxMjM0NTYuY29tIiwiZW1haWwiOiIzMzIxMzM3OTk0QHFxLmNvbSIsImF1dGgiOiJNek15TVRNek56azVORG94TWpNME5UWXVZMjl0XXXX" | base64 --decode

{"ccr.ccs.tencentyun.com/XXXXXXX":{"username":"3321337XXX","password":"123456.com","email":"3321337XXX@qq.com","auth":"MzMyMTMzNzk5NDoxMjM0NTYuY29t"}}
```

## `kubernetes.io/service-account-token`
`Service Account`用来访问`Kubernetes API`，由`Kubernetes`自动创建，并且会自动挂载到`Pod`的`/run/secrets/kubernetes.io/serviceaccount`目录中。