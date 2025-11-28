#!/bin/bash

set -e

echo "===== 配置 Docker 阿里云加速器 ====="
MIRROR_URL="https://registry.aliyuncs.com"

sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": ["$MIRROR_URL"]
}
EOF

echo "===== 重启 Docker 服务 ====="
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "===== 拉取测试镜像 ====="
docker pull mysql:8.1
docker pull redis:7
docker pull hello-world

echo "===== 运行测试容器 ====="
# MySQL 测试容器
docker run --name test-mysql -e MYSQL_ROOT_PASSWORD=123456 -d mysql:8.1

# Redis 测试容器
docker run --name test-redis -d redis:7

# Hello World 测试
docker run hello-world

echo "===== 测试完成，查看容器状态 ====="
docker ps
echo "===== 脚本执行完成 ====="

