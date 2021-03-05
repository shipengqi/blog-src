#!/bin/bash
set -e

# 生成 public
hugo

cd ./public

# 如果是发布到自定义域名
# echo 'www.example.com' > CNAME

git init
git config user.name 'shipengqi'
git config user.email 'pooky.shipengqi@gmail.com'
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# 如果发布到 https://<USERNAME>.github.io
git push -f git@github.com:shipengqi/shipengqi.github.io.git master

# 如果发布到 https://<USERNAME>.github.io/<REPO>
# git push -f git@github.com:<USERNAME>/<REPO> master:gh-pages
