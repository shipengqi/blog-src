#!/bin/bash
set -e

function show_help() {
cat << EOF
Usage: $0 {options}

Options:
  --help
    Display this help screen

  --start
    启动服务

  --port
    指定监听的端口

  --deploy
    部署到github

  --proxy
    配置代理，参数可选，没有参数即使用默认代理。
    配合deploy使用, e.g: --proxy="http://proxy.com"
    注意"="必须有

  --theme
    配合 deploy 使用, 部属时需要制定使用的主题，默认是 cactus
EOF
}


port=8081
useProxy="false"
proxy="http://web-proxy.il.softwaregrp.net:8080"
executeCommand="start"
theme="cactus"
TEMP=`getopt -o hsdp: --long help,start,deploy,theme,port:,proxy:: -n './run.sh --help' -- "$@"`
if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi
 
eval set -- "$TEMP"

while true
do
    case "$1" in
        -h|--help)
            show_help
            exit 2
        ;;
        -s|--start)
            executeCommand="start"
            shift
        ;;
        -d|--deploy)
            executeCommand="deploy"
            shift
        ;;
        --theme)
            theme=$2
            shift
        ;;
        -p|--port)
            port=$2
            shift 2
        ;;
        --proxy)
            useProxy="true"
            if [[ $2 != "" ]];then
                proxy=$2
            fi
            echo "Using proxy: ${proxy}."
            shift 2
        ;;
        --)
            shift
            break
        ;;
        *)
            echo "Internal error!"
            exit 1
        ;;
    esac
done

#todo check port
function start() {
    hexo s -p $port
    if [[ $? -eq 0 ]];then
        echo "启动成功"
    else
        echo "启动失败!"
        exit 4
    fi
}

function deploy() {
    if [[ ${useProxy} == "true" ]];then
        set_proxy
    fi
    if [[ ${theme} == "next" ]];then
        hexo clean
        hexo g
        export HEXO_ALGOLIA_INDEXING_KEY=fff267b07b3a0db8d496a17fe3601667
        hexo algolia
        hexo d
        exit 0
    fi
    if [[ ${theme} == "cactus" ]];then
        hexo clean
        hexo g
        hexo d
        exit 0
    fi
}

function set_proxy() {
  export http_proxy=$proxy
  export https_proxy=$http_proxy
  export HTTP_PROXY=$http_proxy
  export HTTPS_PROXY=$http_proxy
  export no_proxy=127.0.0.1,localhost,.hpe.com,.hp.com,.hpeswlab.net
  export NO_PROXY=$no_proxy
}

if [[ ${executeCommand} == "start" ]];then
	start
elif [[ ${executeCommand} == "deploy" ]];then
   if [[ ${theme} != "next" && ${theme} != "cactus" ]];then
     echo "Unsupported theme."
     exit 1
   fi
	deploy
else
	show_help
	exit 2
fi
