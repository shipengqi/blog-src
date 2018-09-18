#!/bin/bash
# Prepare:
# yarn global add pm2
# cd <project_dir>
# pm2 init
# vim ecosystem.config.js
# e.g.
#  apps : [{
#    name      : 'install',
#    script    : 'npm_install.sh',
#    env: {
#      NODE_ENV: 'development'
#    },
#    env_production : {
#      NODE_ENV: 'production'
#    }
#  }]
# pm2 start ecosystem.config.js
# pm2 ls
# pm2 logs <id>

# exit on errors
set -e

echo ""
echo "-----------------------------------------------------------"
echo "                 Sactive npm install script                "
echo "-----------------------------------------------------------"

install_web() {
  echo "Install web ..."
  yarn add sactive-web eslint-config-sactive && \
  yarn remove sactive-web eslint-config-sactive && \
  yarn cache clean sactive-web && \
  yarn cache clean eslint-config-sactive
}

install_bot() {
  echo "Install bot ..."
  yarn add sactive-bot eslint-config-sactive && \
  yarn remove sactive-bot eslint-config-sactive && \
  yarn cache clean sactive-bot && \
  yarn cache clean sactive-web && \
  yarn cache clean sactive-di && \
  yarn cache clean sbot-conversation && \
  yarn cache clean eslint-config-sactive
}

install_di() {
  echo "Install di ..."
  yarn add sactive-di eslint-config-sactive && \
  yarn remove sactive-di eslint-config-sactive && \
  yarn cache clean sactive-di && \
  yarn cache clean eslint-config-sactive
}

install_nothing() {
  echo "Install nothing ..."
  echo "Continue ..."
}


rand(){  
  min=$1  
  max=$(($2-$min+1))  
  num=$(($RANDOM+1000000000)) #增加一个10位的数再求余  
  echo $(($num%$max+$min))  
}

count=1
total=10000
while [ $count -le $total ]
do
  echo "Installing count: $count"
  random=$(rand 1 4)
  echo "random: $random"
  case $random in
    1)
      install_web
    ;;
    2)
      install_bot
    ;;
    3)
      install_di
    ;;
    4)
      install_nothing
    ;;
  esac
  let "count++"
done
