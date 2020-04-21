---
title: Nginx 配置
date: 2017-09-20 19:38:54
categories: ["Linux"]
tags: ["Nginx"]
---

Nginx 默认配置文件：`/usr/local/nginx/conf/nginx.conf`
<!-- more -->

## Nginx 全局变量
- $arg_PARAMETER #包含GET请求中，如果有变量PARAMETER时的值。
- $args #等于请求行中(GET请求)的参数，例如foo=123&bar=blahblah;
- $binary_remote_addr #二进制的客户地址。
- $body_bytes_sent #响应时送出的body字节数数量。即使连接中断，这个数据也是精确的。
- $content_length #请求头中的Content-length。
- $content_type #请求头中的Content-Type。
- $cookie_COOKIE #cookie COOKIE变量的值
- $document_root #当前请求在root指令中指定的值。
- $document_uri #与$uri相同。
- $host #请求主机头字段，否则为服务器名称。
- $hostname #Set to the machine’s hostname as returned by gethostname
- $http_HEADER
- $is_args #如果有$args参数，这个变量等于”?”，否则等于”"，空值。
- $http_user_agent #客户端agent信息
- $http_cookie #客户端cookie信息
- $limit_rate #这个变量可以限制连接速率。
- $query_string #与$args相同。
- $request_body_file #客户端请求主体信息的临时文件名。
- $request_method #客户端请求的动作，通常为GET或POST。
- $remote_addr #客户端的IP地址。
- $remote_port #客户端的端口。
- $remote_user #已经经过Auth Basic Module验证的用户名。
- $request_completion #如果请求结束，设置为OK. 当请求未结束或如果该请求不是请求链串的最后一个时，为空(Empty)。
- $request_method #GET或POST
- $request_filename #当前请求的文件路径，由root或alias指令与URI请求生成。
- $request_uri #包含请求参数的原始URI，不包含主机名，如：”/foo/bar.php?arg=baz”。不能修改。
- $scheme #HTTP方法（如http，https）。
- $server_protocol #请求使用的协议，通常是HTTP/1.0或HTTP/1.1。
- $server_addr #服务器地址，在完成一次系统调用后可以确定这个值。
- $server_name #服务器名称。
- $server_port #请求到达服务器的端口号。
- $uri #不带请求参数的当前URI，$uri不包含主机名，如”/foo/bar.html”。该值有可能和$request_uri 不一致。
- $request_uri是浏览器发过来的值。该值是rewrite后的值。例如做了internal redirects后。

## 配置介绍

``` nginx
# 守护进程模式
daemon on;
# 配置用什么用户启动
user admin admin;

# 主进程带子进程的模式
master_process on;
# 进程数，建议和CPU核数一致
# PS: tengine可以把设置成auto, http://segmentfault.com/q/1010000000132550
worker_processes auto;
worker_cpu_affinity auto;

# 单个worker进程可以同时处理多少个文件,可以需要和ulimit -a对应
# 个人觉得类似apache的MaxRequestsPerChild
worker_rlimit_nofile 10240;

# worker进程的优先级，不能小于等于-5
worker_priority 0;

# 输出日志地址
error_log logs/error.log warn;
pid logs/nginx.pid;
lock_file logs/nginx.lock;

events {
    # # 一个worker进程能够同时连接的数量
    worker_connections 10240;
    # event的模型类型;
    use epoll;
    # 启用一个接受互斥锁来打开套接字监听
    accept_mutex on;
    # 定义一个worker进程在尝试再次获取资源之前等待多久
    accept_mutex_delay 500ms;
    # 是否立刻接受从所有监听队列进入的连接
    multi_accept off;
}

http {
    include       mime.types;
    default_type  text/plain;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    # 当资源没有找到时，是否log
    log_not_found off;

    # nginx将启用 sendfile内核来调用处理文件传递
    sendfile        on;
    # 配合sendfile，开启TCP_CORK的socket选项
    # nginx将尝试在单个tcp数据包中发送整个http响应头
    #tcp_nopush     on;

    # 需要完全禁用keepalive的话，将这个值设置成0
    keepalive_timeout  75; # 对应到apache的KeepAliveTimeout
    keepalive_requests 1000;  # 对应到apache的MaxKeepAliveRequests

    # 客户端两次读取操作的最大延迟, 对应apache的Timeout
    send_timeout 10;

    # hide nginx version,对等apache的ServerTokens
    server_tokens off;

    # 反向代理相关配置:
    # 包括传递给后端服务器的请求头信息，关闭对相应中的Location头信息和Refresh头信息做文本替换，以及设置缓冲区大小
    # 转发到后端服务器的请求中的Host HTTP头默认为代理的主机名,这样的设置令nginx可以换而使用客户端请求中的原始主机名
    proxy_set_header        Host $host;
    # 让后端机器得到真实的IP
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        Web-Server-Type nginx;
    proxy_set_header        WL-Proxy-Client-IP $remote_addr;
    # 确保用于套接字通讯的IP地址
    proxy_set_header        X-Forwarded-For    $proxy_add_x_forwarded_for;
    # 让nginx以“ as it is”方式重定向到客户端，对响应本身不做处理
    proxy_redirect          off;
    # 是否缓冲后端服务器的响应
    proxy_buffering on;
    # 设置缓冲数量大小，用于存放从后端服务器读取的响应数据
    # 128 8k的意思是128个缓冲，每个缓冲8k
    # TODO 这个需要测试
    proxy_buffers           256 32k;
    # 缓冲区的大小，得和上面的proxy_buffers对应
    proxy_buffer_size 32k;
    # 超过多少后缓冲去刷新，通常配置成proxy_buffer_size * 2
    proxy_busy_buffers_size 64k;
    # 代理的超时
    # 连接超时
    proxy_connect_timeout 60;
    # 读取超时
    proxy_read_timeout 60;
    # 发送超时
    proxy_send_timeout 60;
    # 如果客户端放弃请求，那么nginx也放弃
    proxy_ignore_client_abort off;
    # 当后端错误时，根据后端的返回码，来匹配自身的error_page的值
    proxy_intercept_errors  on;

    # URL 重定向为： server_name 中的第一个域名 + 目录名 + /
    # 如果是off的话： 原 URL 中的域名 + 目录名 + /
    server_name_in_redirect on;

    # 限制客户端请求体的最大值
    # TODO 这个需要再确认一下
    client_max_body_size 20M;
    # 定义用于持有request body内存缓冲的大小。超过该大小，内容将被保存到临时文件中
    # TODO 这个也需要再确认
    client_body_buffer_size 128k;

    # gzip
    gzip on;
    gzip_min_length 1k;  # 大于多少才压缩
    gzip_http_version       1.0;   # 用了反向代理的话，末端通信是HTTP/1.0
    gzip_buffers 4 16k;
    gzip_comp_level 2;  # 压缩级别，9是最大
    gzip_types text/plain application/x-javascript text/css application/xml text/javascript application/rss+xml application/json;
    gzip_vary off;  # on的话会在Header里增加"Vary: Accept-Encoding"
    gzip_disable     "MSIE [1-6]\.";
    #添加 weight 字段可以表示权重，值越高权重越大，默认值是 1
    upstream neo_proxy {
        server 127.0.0.1:3005 weight=1;
        server 127.0.0.1:3004 weight=1;
    }
    server {
        listen       3003;
        server_name  neo.benditoutiao.com;
        access_log  logs/neo_benditoutiao_com_access.log  main;

       # 跳转到实际的服务
       location / {
           proxy_pass http://neo_proxy/;
       }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }

}
```
例： `server 127.0.0.1:3005 weight=1 max_fails=3 fail_timeout=10 backup;`
`upsrteam`参数说明:

- `server 127.0.0.1:3005`： 负载均衡后面的RS配置，可以使IP或者域名，端口不写，默认是80，高并发场景下，IP可以换成域名，通过DNS做负载均衡。
- `weight=1`： 代表服务器权重，默认值是1，值越大，接受请求的比例越大。
- `max_fails=3`： Nginx尝试连接后端主机失败的次数，配合`proxy_next_upstream`，`fastcgi_next_upstream`，`memcached_next_upstream`这三个参数使用。
- `fail_timeout=10`： 在定义`max_fails`之后，距离下次检查的间隔时间，默认是10秒，`max_fails`定义几次就检查几次，如果每次都是失败，就会根据`fail_timeout`的值，如果fail_timeout=10，就等待10秒后再去检查，只检查一次，如果持续失败，每隔10秒检查一次，常见2-3秒比较合理。
- `backup`： 热备配置，当前面的RS全部激活失败后会启用热备，当主服务全部失败，就会向它转发请求。 
- `down`： 标志着个服务器永远不可用。

### 配置 HTTPS
``` nginx
#http重定向到https
server {
   listen 80 default_server;
   server_name   {domain-name} ;
   return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl;
  server_name    {domain-name} ;

  #crt 和 key 文件的存放位置根据你自己存放位置进行修改
  ssl on;
  ssl_certificate /etc/nginx/ssl/my.crt;
  ssl_certificate_key /etc/nginx/ssl/my.key;
  #ssl_certificate /etc/letsencrypt/live/{domain-name}/fullchain.pem;
  #ssl_certificate_key /etc/letsencrypt/live/{domain-name}/privkey.pem;
  #ssl_session_timeout 5m;
  #ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  #ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
  #ssl_prefer_server_ciphers on;
  #ssl_session_cache shared:SSL:10m;

  location / {
     root   html;
     index  index.html index.htm;
  }
  error_page   500 502 503 504  /50x.html;
  location = /50x.html {
     root   html;
  }
}
```

### location 配置
``` nginx
= 开头表示精确匹配
^~ 开头表示uri以某个常规字符串开头，不是正则匹配
~ 开头表示区分大小写的正则匹配;
~* 开头表示不区分大小写的正则匹配
/ 通用匹配, 如果没有其它匹配,任何请求都会匹配到

location / {

}

location /user {

}

location = /user {

}

location /user/ {

}

location ^~ /user/ {

}

location /user/youmeek {

}

location ~ /user/youmeek {

}

location ~ ^(/cas/|/casclient1/|/casclient2/|/casclient3/) {

}

location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|ico|woff|woff2|ttf|eot|txt)$ {

}

location ~ .*$ {

}
```

### Nginx站点缓存设置
网站上线后，有些变化很少的静态资源，如：css、图片、font、js等，可以设置客户端缓存时间，以减少http请求，提高网站运行效率。我们可以利用nginx缓存服务器的静态资源，达到优化站点目的。
可以使用Nginx的proxy_cache将用户的请求缓存到一个本地目录下，当下次请求时可以直接读取缓存文件，达到减少服务器请求次数的目的。
``` nginx
proxy_connect_timeout 10;
proxy_read_timeout 180;
proxy_send_timeout 5;
proxy_buffer_size 16k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 256k;
proxy_temp_file_write_size 256k;
proxy_temp_path /tmp/site_cache; proxy_cache_path /tmp/cache levels=1:2 keys_zone=cache_one:100m inactive=1d max_size=1g;
```
设置临时目录：proxy_temp_path /tmp/site_cache;
设置缓存目录：proxy_cache_path /tmp/cache levels=1:2 keys_zone=cache_one:100m inactive=1d max_size=1g;
levels设置目录层次，keys_zone设置缓存名字和共享内存大小，inactive在指定时间内没人访问则被删除在这里是1天，max_size最大缓存空间。

在server节点设置要缓存文件的后缀，配置如下：
``` nginx
location ~ .*\.(gif|jpg|png|css|js|eot|svg|ttf|woff|otf)(.*) {
  proxy_pass http://127.0.0.1:3000;
  proxy_redirect off;
  proxy_set_header Host $host;
  proxy_cache cache_one;
  proxy_cache_valid 200 302 24h;
  proxy_cache_valid 301 30d;
  proxy_cache_valid any 5m; expires 30d;
}
```
非缓存页面跳转对应站点：proxy_pass http://127.0.0.1:3000;
设置缓存共享内存：proxy_cache cache_one;
设置http状态码为200,302缓存时间，24h为24小时：proxy_cache_valid 200 302 24h;
设置失期时间为30天：expires 30d

### Nginx配置gzip压缩
网站有大量CSS、JS文件时，网站打开速度会比较慢，开启Nginx的gzip压缩功能，可以明显提高浏览速度。
默认情况下，Nginx的gzip压缩是关闭的，需要手动开启 。gzip是GNU zip的缩写，它是一个GNU自由软件的文件压缩程序，可以极大的加快网站访问速度。
``` nginx
gzip on;
gzip_min_length 1k;
gzip_buffers 4 16k;
gzip_http_version 1.0;
gzip_comp_level 5;
gzip_types text/plain application/x-javascript text/css application/xml application/javascript;
gzip_vary on;
```
gzip
语法：gzip on|off
默认值：gzip off
作用域:http,server,location,if (x) location
开启或者关闭gzip模块


gzip_buffers
语法：gzip_buffers number size
默认值：gzip_buffers 4 4k/8k
作用域：http,server,location
设置系统获取几个单位的缓存用于存储gzip的压缩结果数据流。例如 4 4k 代表以4k为单位，按照原始数据大小以4k为单位的4倍申请内存。4 8k 代表以8k为单位，按照原始数据大小以8k为单位的4倍申请内存。
如果没有设置，默认值是申请跟原始数据相同大小的内存空间去存储gzip压缩结果。


gzip_comp_level
语法：gzip_comp_level 1..9
默认值：gzip_comp_level 1
作用域：http,server,location
gzip压缩比：1 压缩比最小处理速度最快，9 压缩比最大但处理最慢（更高的压缩率会更消耗cpu）。


gzip_min_length
语法：gzip_min_length length
默认值：gzip_min_length 0
作用域：http,server,location
设置允许压缩的页面最小字节数，页面字节数从header头中的Content-Length中进行获取。
默认值是0，不管页面多大都压缩。
建议设置成大于1k的字节数，小于1k可能会越压越大。即： gzip_min_length 1024


gzip_http_version
语法：gzip_http_version 1.0|1.1
默认值：gzip_http_version 1.1
作用域：http,server,location
识别http的协议版本。由于早期的一些浏览器或者http客户端，可能不支持gzip自解压，用户就会看到乱码，所以做一些判断还是有必要的。注：21世纪都来了，现在除了类似于百度的蜘蛛之类的东西不支持自解压，99.99%的浏览器基本上都支持gzip解压了，所以可以不用设这个值，保持系统默认即可。


gzip_proxied
语法：gzip_proxied [off|expired|no-cache|no-store|private|no_last_modified|no_etag|auth|any] ...
默认值：gzip_proxied off
作用域：http,server,location
Nginx作为反向代理的时候启用，开启或者关闭后端服务器返回的结果，匹配的前提是后端服务器必须要返回包含"Via"的 header头。
off - 关闭所有的代理结果数据的压缩 expired - 启用压缩，如果header头中包含 "Expires" 头信息 no-cache - 启用压缩，如果header头中包含 "Cache-Control:no-cache" 头信息 no-store - 启用压缩，如果header头中包含 "Cache-Control:no-store" 头信息 private - 启用压缩，如果header头中包含 "Cache-Control:private" 头信息 no_last_modified - 启用压缩，如果header头中不包含 "Last-Modified" 头信息 no_etag - 启用压缩，如果header头中不包含 "ETag" 头信息 auth - 启用压缩，如果header头中包含 "Authorization" 头信息 any - 无条件启用压缩


gzip_types
语法：gzip_types mime-type [mime-type ...]
默认值：gzip_types text/html
作用域：http,server,location
匹配MIME类型进行压缩，无论是否指定"text/html"类型总是会被压缩的。
建议只压缩文本类型的内容，image/jpeg image/gif image/png等图片类型没有必要压缩。
注意：如果作为http server来使用，主配置文件中要包含文件类型配置文件
http{ include conf/mime.types; ......}
如果你希望压缩常规的文件类型，可以写成这个样子
``` nginx
http {
  include conf/mime.types;
  gzip on;: gzip_min_length 1000;
  gzip_buffers 4 8k; : gzip_http_version 1.1;
  gzip_types text/plain application/x-javascript text/css text/html application/xml;
}
```

### nginx 日志分割
- 前提：
	- 我 nginx 的成功日志路径：/var/log/nginx/access.log
	- 我 nginx 的错误日志路径：/var/log/nginx/error.log
	- pid 路径：/var/local/nginx/nginx.pid

- 一般情况 CentOS 是装有：logrotate，你可以检查下：`rpm -ql logrotate`，如果有相应结果，则表示你也装了。
- logrotate 配置文件一般在：
	- 全局配置：/etc/logrotate.conf 通用配置文件，可以定义全局默认使用的选项。
	- 自定义配置，放在这个目录下的都算是：/etc/logrotate.d/

- 针对 nginx 创建自定义的配置文件：`vim /etc/logrotate.d/nginx`
- 文件内容如下：

``` ini

/var/log/nginx/access.log /var/log/nginx/error.log {
	create 644 root root
	notifempty
	daily
	rotate 15
	missingok
	dateext
	sharedscripts
	postrotate
	    if [ -f /var/local/nginx/nginx.pid ]; then
	        kill -USR1 `cat /var/local/nginx/nginx.pid`
	    fi
	endscript
}

```

- /var/log/nginx/access.log /var/log/nginx/error.log：多个文件用空格隔开，也可以用匹配符：/var/log/nginx/*.log
- notifempty：如果是空文件的话，不转储
- create 644 root root：create mode owner group 转储文件，使用指定的文件模式创建新的日志文件
- 调用频率，有：daily，weekly，monthly可选
- rotate 15：一次将存储15个归档日志。对于第16个归档，时间最久的归档将被删除。
- sharedscripts：所有的日志文件都轮转完毕后统一执行一次脚本
- missingok：如果日志文件丢失，不报错继续执行下一个
- dateext：文件后缀是日期格式,也就是切割后文件是:xxx.log-20131216.gz 这样,如果注释掉,切割出来是按数字递增,即前面说的 xxx.log-1 这种格式
- postrotate：执行命令的开始标志
- endscripthttp:执行命令的结束标志
- if 判断的意思不是中止Nginx的进程，而是传递给它信号重新生成日志，如果nginx没启动不做操作
- 更多参数可以看：<http://www.cnblogs.com/zengkefu/p/5498324.html>


- 手动执行测试：`/usr/sbin/logrotate -vf /etc/logrotate.d/nginx`
- 参数：‘-f’选项来强制logrotate轮循日志文件，‘-v’参数提供了详细的输出。
- 验证是否手动执行成功，查看 cron 的日志即可：`grep logrotate /var/log/cron`
- 设置 crontab 定时任务：`vim /etc/crontab`，添加下面内容：

``` ini
//每天02点10分执行一次
10 02 * * *  /usr/sbin/logrotate -f /etc/logrotate.d/nginx
```

### nginx_upstream_check_module检查负载均衡服务器的健康情况
nginx做反代，如果后端服务器宕掉的话，nginx是不能把这台realserver提出upstream的，所以还会有请求转发到后端的这台realserver上面去，
虽然nginx可以在localtion中启用proxy_next_upstream来解决返回给用户的错误页面，但这个还是会把请求转发给这台服务器的，然后再转发给别的服务器，这样就浪费了一次转发，
借助淘宝技术团队开发的nginx模快nginx_upstream_check_module来检测后方realserver的健康状态，如果后端服务器不可用，则所以的请求不转发到这台服务器。

#### 下载nginx的模块https://github.com/yaoweibin/nginx_upstream_check_module
``` bash
wget https://github.com/yaoweibin/nginx_upstream_check_module/archive/v0.3.0.tar.gz
tar -xvf v0.3.0.tar.gz
```
作为OpenResty第三方模块编译安装之后，在nginx.conf配置文件里面的upstream加入健康检查:
``` nginx
upstream test {
  server 192.168.0.21:80;
  server 192.168.0.22:80;
  check interval=3000 rise=2 fall=5 timeout=1000;
}
```
interval检测间隔时间，单位为毫秒，rsie请求2次正常的话，标记此realserver的状态为up，fall表示请求5次都失败的情况下，标记此realserver的状态为down，timeout为超时时间，单位为毫秒。
在server段里面可以加入查看realserver状态的页面
``` nginx
location /nstatus {
  check_status;
  access_log off;
  #allow SOME.IP.ADD.RESS;
  #deny all;
}
```
打开nstatus这个页面就可以看到当前realserver的状态了

### Nginx服务器涉及到的安全配置


### Nginx利用image_filter动态生成缩略图
网站上不同的页面需要不同尺寸的图片，或用户上传的图片尺寸不符合页面显示的规范，因此需要对图片尺寸进行加工。
Nginx提供了一个图片处理模块：http_image_filter_module，可以方便的对图片进行缩放、旋转等操作，可以实时对图片进行处理，支持nginx-0.7.54以后的版本。

#### 安装gd-devel
http_image_filter_module依赖gd-devel库，因此安装http_image_filter_module模块前需要首先安装gd-devel库。
``` bash
\\Redhat、Centos
yum install -y gd-devel
\\Debian、Ubuntu
apt-get install libgd2-xpm libgd2-xpm-dev
```
#### 安装http_image_filter_module
默认HttpImageFilterModule模块是不会编译进nginx的，所以要在configure时候指定
``` bash
./configure arguments: --prefix=/usr/local/nginx --with-http_image_filter_module
make && make install
```
#### 配置使用
``` nginx
root /home/www/zszsgc/public; #站点根目录
location ~ "^(/upload/.*\.(jpg|png|jpeg))!(\d+)-(\d+)$" {
  set $w $3;
  set $h $4;
  rewrite ^(/upload/.*\.(jpg|png|jpeg))!(\d+)-(\d+)$ $1 break;
  image_filter resize $w $h; #按宽高对图片进行压缩
  image_filter_buffer 2M; #设置图片缓冲区的最大大小，大小超过设定值，服务器将返回错误415
  if (!-f $request_filename) {
    proxy_pass http://127.0.0.1:3000;
  }
  try_files $1 404;
}
```
image_filter：
测试图片文件合法性（image_filter test）；
3个角度旋转图片（image_filter rotate 90 | 180 | 270）；
以json格式输出图片宽度、高度、类型（image_filter size）；
最小边缩小图片保持图片完整性（resize width height）；
以及最大边缩放图片后截取多余的部分（image_filter crop [width] [height]）

image_filter_jpeg_quality ：设置jpeg图片的压缩质量比例（官方最高建议设置到95，但平时75就可以了）；

image_filter_buffer ：限制图片最大读取大小，默认为1M,该指令设置单图片缓存的最大值，如果过滤的图片大小超过缓存大小，会报错返回415；

image_filter_transparency：用来禁用gif和palette-based的png图片的透明度，以此来提高图片质量。

#### 检测配置
``` bash
# nginx -t -->检测配置是否正确
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
# nginx -s reload -->使配置生效
```
以上规则将匹配/upload文件夹及其子文件夹下的.jpg.png.jpeg格式文件，如果文件名后有：!宽-高，格式的参数将按宽高进行压缩。
例如，有尺寸为980*735的源图片，图片网址为：
http://www.example.com/path/to/image/http_image_filter_module.jpg
现压缩为尺寸为320*250的缩略图，图片网址为：
http://www.example.com/path/to/image/http_image_filter_module.jpg!320-250

以上仅实现了网站中常用的图片压缩功能，[http_image_filter_module模块官方介绍](http://nginx.org/en/docs/http/ngx_http_image_filter_module.html)

### ngx_cache_purge清理nginx缓存
下载ngx_cache_purge模块，该模块用于清理nginx缓存
``` bash
wget https://github.com/FRiCKLE/ngx_cache_purge/archive/2.3.tar.gz
tar -xvf 2.3.tar.gz
```
#配置nginx cache 和ngx_cache_purge
``` nginx
  proxy_cache_path /var/nginx/cache levels=1:2 keys_zone=cache_one:200m inactive=15d max_size=100g;
  proxy_cache_key  "$request_uri";
  proxy_cache cache_one;
  proxy_cache_valid 200 15d;
  expires 15d;

  #仅允许本地网络清理缓存
  location ~ /purge(/.*) {
    allow   106.2.214.50;
    allow   127.0.0.1;
    allow   192.168.5.0/24;
    deny    all;
    proxy_cache_purge   cache_one   $1$is_args$args;
  }

```
Key : /文件路径/文件名
Path: /var/nginx/cache/xxxxxxxxx
如果这个文件发生了变化，则需要刷新缓存，访问文件，就会提示：Successful purge
如果这个文件没有被缓存过，则提示：404 Not Found

### 网站动静分离
#### 基于目录（uri）进行转发
根据HTTP的URL进行转发的应用情况，被称为第7层（应用层）的负载均衡，而LVS的负载均衡一般用于TCP等的转发，因此被称为第4层（传输层）的负载均衡。
``` nginx
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';                     
    upstream upload_pools {
      server 10.0.0.8:80;
    }

    upstream static_pools {
      server 10.0.0.7:80;
    }

    upstream default_pools {
      server 10.0.0.9:80;
    }

    server {
        listen 80;
        server_name www.example.com;
		location /static/ {
			proxy_pass http://static_pools;
			proxy_set_header Host $host;
			proxy_set_header X-Forwarded-For $remote_addr;
		}

		location /upload/ {
			proxy_pass http://upload_pools;
			proxy_set_header Host $host;
			proxy_set_header X-Forwarded-For $remote_addr;
		}

		location / {
			proxy_pass http://default_pools;
			proxy_set_header Host $host;
			proxy_set_header X-Forwarded-For $remote_addr;
		}
        access_log  logs/access_www.log  main;
    }
}

```
#### 根据客户端的设备实现转发（user_agent）
``` nginx
worker_processes  1;
events {
     worker_connections  1024;
}
http {
     include       mime.types;
     default_type  application/octet-stream;
     sendfile        on;
     keepalive_timeout  65;
     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for"';
    upstream upload_pools {
       server 10.0.0.8:80;
    }
    upstream static_pools {
       server 10.0.0.7:80;
    }
    upstream default_pools {
       server 10.0.0.9:80;
    }
    server {
        listen 80;
        server_name www.example.com;
        location / {
            if ($http_user_agent ~* "MSIE")
            {
                proxy_pass http://static_pools;
            }
            if ($http_user_agent ~* "Chrome")
            {
                proxy_pass http://upload_pools;
            }
            proxy_pass http://default_pools;
            proxy_set_header Host $host;
        }
        access_log  logs/access_www.log  main;
     }
}

```

#### 利用扩展名进行转发
``` nginx
worker_processes  1;
events {
     worker_connections  1024;
}
http {
     include       mime.types;
     default_type  application/octet-stream;
     sendfile        on;
     keepalive_timeout  65;
     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                       '$status $body_bytes_sent "$http_referer" '
                       '"$http_user_agent" "$http_x_forwarded_for"';
    upstream upload_pools {
       server 10.0.0.8:80;
    }
    upstream static_pools {
       server 10.0.0.7:80;
    }
    upstream default_pools {
       server 10.0.0.9:80;
    }
    server {
        listen 80;
        server_name www.example.com;
		location ~.*.(gif|ipg|jpeg|png|bmp|swf|css|js)$ {
		    peoxy_pass http://static_pools;
		    include proxy.conf
		}

        access_log  logs/access_www.log  main;
     }
}

```

### 安全配置

1. 禁止一个目录的访问
示例：禁止访问path目录
``` nginx
location ^~ /path {
  deny all;
}
```
可以把path换成实际需要的目录，目录path后是否带有”/”,带“/”会禁止访问该目录和该目录下所有文件。不带”/”的情况就有些复杂了，只要目录开头匹配上那个关键字就会禁止；注意要放在fastcgi配置之前。
2. 禁止php文件的访问及执行
示例：去掉单个目录的PHP执行权限
``` nginx
location ~ /attachments/.*\.(php|php5)?$ {
  deny all;
}
```
示例：去掉多个目录的PHP执行权限
``` nginx
location ~ /(attachments|upload)/.*\.(php|php5)?$ {
  deny all;
}
```
3. 禁止IP的访问
示例：禁止IP段的写法：
deny 10.0.0.0/24;
示例：只允许某个IP或某个IP段用户访问，其它的用户全都禁止
allow
x.x.x.x;
allow 10.0.0.0/24;
deny all;

5. 安全相预防
在配置文件中设置自定义缓存以限制缓冲区溢出攻击的可能性
client_body_buffer_size 1K;
client_header_buffer_size 1k;
client_max_body_size 1k;
large_client_header_buffers 2 1k;

6. 将timeout设低来防止DOS攻击
所有这些声明都可以放到主配置文件中。
client_body_timeout 10;
client_header_timeout 10;
keepalive_timeout 5 5;
send_timeout 10;


7. 限制用户连接数来预防DOS攻击
limit_zone slimits $binary_remote_addr 5m;
limit_conn slimits 5;

### Nginx高可用
//Todo
- Keepalived
	- 官网：<http://www.keepalived.org/>
	- 官网下载：<http://www.keepalived.org/download.html>
	- 官网文档：<http://www.keepalived.org/documentation.html>
- <http://xutaibao.blog.51cto.com/7482722/1669123>
- <https://m.oschina.net/blog/301710>
- <http://blog.csdn.net/u010028869/article/details/50612571>
- <http://blog.csdn.net/wanglei_storage/article/details/51175418>


更多参考[Nginx中文文档](http://www.nginx.cn/doc/)