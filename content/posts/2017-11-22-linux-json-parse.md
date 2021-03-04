---
title: Linux jq 使用
date: 2017-11-22 15:32:04
categories: ["Linux"]
---

`jq` 是一个很好用的处理 json 的工具，可以使用它直接在命令行下对 json 进行操作，分片、过滤、映射和转换。

<!--more-->

## 安装

```bash
# ubuntu安装
apt-get update
apt-get install jq

# 编译安装
git clone https://github.com/stedolan/jq.git
cd jq
autoreconf -i
./configure --disable-maintainer-mode
make
sudo make install
```

## 简单使用

### 格式化输出

如 `test.json` 文件的内容：

```json
[{"name":"xiaoming","age":"18","address":{"city":"上海","country":"中国"},"contacts":[{"phone":"132156465"}]}]
```

格式化输出：

```bash
cat test.json | jq '.'
# 或者
jq '.' test.json
```

输出：

``` json
[
  {
    "name":"xiaoming",
 "age":"18",
 "address":{
   "city":"上海",
   "country":"中国"
 },
 "contacts": [
   {
     "phone":"132156465"
   }
 ]
  }
]
```

### 访问 json 对象的属性

访问元素的操作: `.<attributename>` 和 `.[index]`。
`jq` 支持管道 `|`，它如同 linux 命令中的管道线——把前面命令的输出当作是后面命令的输入。
如下命令把 `.[0]` 作为 `{...}` 的输入，进而访问嵌套的属性，如 `.name` 和 `.address.city`。

``` bash
cat test.json | jq '.[0] | {name:.name,city:.address.city}'

# 输出：

{
  "name": "xiaoming",
  "city": "上海"
}

cat test.json | jq '.[0] | {phone:.contacts[0].phone,city:.address.city}'

#输出：

{
  "phone": "132156465",
  "city": "上海"
}
```

### 修改 json

``` bash
# 修改属性的值，重定向到新的文件
MM_FILE=info.json
MM_AGE=18
get_name() {
  return 'xiaoming'
}
jq '.people.address = "shanghai"' $MM_FILE > $MM_FILE.tmp
jq '.people.name = "'$(get_name)'"' $MM_FILE > $MM_FILE.tmp
jq '.people.age = "'${MM_AGE}'"' $MM_FILE > $MM_FILE.tmp

# 输出数组，输出加上`[]`
cat test.json | jq '[.[0] | {name:.name,city:.address.city}]'

# 输出：
[
  {
    "name": "xiaoming",
 "city": "上海"
  }
]

# 添加属性
cat test.json | jq '[.[0] | {name_cp:.name,city_cp:.address.city}]'

# 输出：
[
  {
    "name_cp": "xiaoming",
 "city_cp": "上海"
  }
]
```

## 参考资料

- [官方文档](https://stedolan.github.io/jq/manual/)
