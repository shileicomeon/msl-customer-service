#!/bin/bash

echo "======================================"
echo "马上来智能客服系统 - 快速启动脚本"
echo "======================================"
echo ""

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: 未检测到Docker，请先安装Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "错误: 未检测到Docker Compose，请先安装Docker Compose"
    exit 1
fi

# 检查配置文件
if [ ! -f "backend/config/config.yaml" ]; then
    echo "错误: 未找到配置文件 backend/config/config.yaml"
    exit 1
fi

echo "1. 停止现有服务..."
docker-compose down

echo ""
echo "2. 构建镜像..."
docker-compose build

echo ""
echo "3. 启动服务..."
docker-compose up -d

echo ""
echo "4. 等待服务启动..."
sleep 10

echo ""
echo "5. 检查服务状态..."
docker-compose ps

echo ""
echo "======================================"
echo "服务启动完成！"
echo "======================================"
echo ""
echo "访问地址："
echo "  前端: http://localhost"
echo "  后端: http://localhost:8080"
echo "  健康检查: http://localhost:8080/health"
echo ""
echo "查看日志："
echo "  docker-compose logs -f"
echo ""
echo "停止服务："
echo "  docker-compose down"
echo ""

