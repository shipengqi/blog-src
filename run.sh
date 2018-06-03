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
EOF
}


port=8081
executeCommand="start"
TEMP=`getopt -o hsdp: --long help,start,deploy,port: -n './run.sh --help' -- "$@"`
if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi

#set 将规范化后的命令行参数分配至位置参数（$1,$2,...)
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
            executeCommand="stop"
            shift
        ;;
        -p|--port)
            port=$2
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
    hexo clean
    hexo g
    export HEXO_ALGOLIA_INDEXING_KEY=fff267b07b3a0db8d496a17fe3601667
    hexo algolia
    hexo d
}

if [[ ${executeCommand} == "start" ]];then
	start
elif [[ ${executeCommand} == "deploy" ]];then
	deploy
else
	show_help
	exit 2
fi