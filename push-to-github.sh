#!/bin/bash

# GitHub 仓库推送脚本
# 使用方法: ./push-to-github.sh <your-github-username> <repository-name>

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "使用方法: ./push-to-github.sh <your-github-username> <repository-name>"
    echo "例如: ./push-to-github.sh shialei msl-customer-service"
    exit 1
fi

GITHUB_USER=$1
REPO_NAME=$2

echo "正在添加远程仓库..."
git remote add origin https://github.com/${GITHUB_USER}/${REPO_NAME}.git

echo "正在推送到 GitHub..."
git branch -M main
git push -u origin main

echo "完成！代码已推送到 https://github.com/${GITHUB_USER}/${REPO_NAME}"

