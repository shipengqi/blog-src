---
title: Linux 下使用 AB 进行压力测试
date: 2019-03-06 14:03:23
categories: ["Linux"]
---

Linux 下使用 AB 进行压力测试。



## 安装

AB 测试工具安装：`yum install -y httpd-tools`

## GET 请求

```bash
ab -n 1000 -c 100 http://www.baidu.com/
```

- `-n`，总的请求数
- `-c`，单个时刻并发数

压测结果：

```bash
This is ApacheBench, Version 2.3 <$Revision: 1430300 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking juejin.im (be patient)
Completed 100 requests
Completed 200 requests
Completed 300 requests
Completed 400 requests
Completed 500 requests
Completed 600 requests
Completed 700 requests
Completed 800 requests
Completed 900 requests
Completed 1000 requests
Finished 1000 requests


Server Software:        nginx
Server Hostname:        juejin.im
Server Port:            443
SSL/TLS Protocol:       TLSv1.2,ECDHE-RSA-AES256-GCM-SHA384,2048,256

Document Path:          /
Document Length:        271405 bytes

Concurrency Level:      100（并发数：100）
Time taken for tests:   120.042 seconds（一共用了 120 秒）
Complete requests:      1000（总的请求数：1000）
Failed requests:        0（失败的请求次数）
Write errors:           0
Total transferred:      271948000 bytes
HTML transferred:       271405000 bytes
Requests per second:    8.33 [#/sec] (mean)（QPS 系统吞吐量，平均每秒请求数，计算公式 = 总请求数 / 总时间数）
Time per request:       12004.215 [ms] (mean)（毫秒，平均每次并发 100 个请求的处理时间）
Time per request:       120.042 [ms] (mean, across all concurrent requests)（毫秒，并发 100 下，平均每个请求处理时间）
Transfer rate:          2212.34 [Kbytes/sec] received（平均每秒网络流量）

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:       57  159 253.6     77    1002
Processing:  1139 11570 2348.2  11199   36198
Waiting:      156 1398 959.4   1279   22698
Total:       1232 11730 2374.1  11300   36274

Percentage of the requests served within a certain time (ms)
  50%  11300
  66%  11562
  75%  11863
  80%  12159
  90%  13148
  95%  15814
  98%  18882
  99%  22255
 100%  36274 (longest request)
```

## POST 请求

```bash
ab -n 5000 -c 200 -p data.txt -T application/x-www-form-urlencoded http://your.api
```

- `-p`，请求数据的文件的完整路经。
- `-T`，`Content-Type`。

`-p` 指定文件的格式应该是 `name1=value1&name2=value2`。

**注意，如果是在内网请求外网，要加上 `-X hostname:port`，指定你的 http 代理**。

## 其他参数

可以使用`ab --help`查看：

```bash
Usage: ab [options] [http[s]://]hostname[:port]/path
Options are:
    -n requests     Number of requests to perform
    -c concurrency  Number of multiple requests to make
    -t timelimit    Seconds to max. wait for responses
    -b windowsize   Size of TCP send/receive buffer, in bytes
    -p postfile     File containing data to POST. Remember also to set -T
    -u putfile      File containing data to PUT. Remember also to set -T
    -T content-type Content-type header for POSTing, eg.
                    'application/x-www-form-urlencoded'
                    Default is 'text/plain'
    -v verbosity    How much troubleshooting info to print
    -w              Print out results in HTML tables
    -i              Use HEAD instead of GET
    -x attributes   String to insert as table attributes
    -y attributes   String to insert as tr attributes
    -z attributes   String to insert as td or th attributes
    -C attribute    Add cookie, eg. 'Apache=1234. (repeatable)
    -H attribute    Add Arbitrary header line, eg. 'Accept-Encoding: gzip'
                    Inserted after all normal header lines. (repeatable)
    -A attribute    Add Basic WWW Authentication, the attributes
                    are a colon separated username and password.
    -P attribute    Add Basic Proxy Authentication, the attributes
                    are a colon separated username and password.
    -X proxy:port   Proxyserver and port number to use
    -V              Print version number and exit
    -k              Use HTTP KeepAlive feature
    -d              Do not show percentiles served table.
    -S              Do not show confidence estimators and warnings.
    -g filename     Output collected data to gnuplot format file.
    -e filename     Output CSV file with percentages served
    -r              Don't exit on socket receive errors.
    -h              Display usage information (this message)
    -Z ciphersuite  Specify SSL/TLS cipher suite (See openssl ciphers)
```

## 常见问题

### 当并发设置为 250 以上的时候就会出现 apr_socket_recv Connection refused 111 错误

这是因为是 linux 网络参数设置。一般 apache 默认最大并发量为 150，可以进入配置文件修改 `Threadperchild` 等参数值。

如何调整 Apache 的最大并发量：

```bash
vi /etc/sysctl.conf

net.nf_conntrack_max = 655360

net.netfilter.nf_conntrack_tcp_timeout_established = 1200

sysctl -p /etc/sysctl.conf
```

修改后，重新启用 apache ab 进行测试，问题解决。
