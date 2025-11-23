#!/bin/bash

# 本地开发环境启动脚本

echo "======================================"
echo "马上来智能客服系统 - 本地开发环境"
echo "======================================"
echo ""

cd "$(dirname "$0")"

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker未运行，请先启动Docker Desktop"
    exit 1
fi

# 启动MySQL和Redis
echo "[1/4] 启动MySQL和Redis..."
docker compose up -d mysql redis

# 等待数据库启动
echo "等待数据库启动..."
sleep 5

# 检查数据库是否就绪
until docker exec msl-cs-mysql mysqladmin ping -h localhost --silent; do
    echo "等待MySQL启动..."
    sleep 2
done

echo "✓ MySQL和Redis已启动"
echo ""

# 检查Go是否安装
if ! command -v go &> /dev/null; then
    echo "错误: Go未安装，请先安装Go 1.21+"
    echo "下载地址: https://go.dev/dl/"
    exit 1
fi

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "错误: Node.js未安装，请先安装Node.js 18+"
    echo "下载地址: https://nodejs.org/"
    exit 1
fi

# 启动后端
echo "[2/4] 启动后端服务..."
cd backend

# 安装Go依赖
if [ ! -d "vendor" ]; then
    echo "安装Go依赖..."
    go mod download
fi

# 创建上传目录
mkdir -p uploads

# 在后台启动后端
echo "启动后端服务 (端口: 8080)..."
go run main.go > ../backend.log 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > ../backend.pid

# 等待后端启动
sleep 3

# 检查后端是否启动
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✓ 后端服务已启动"
else
    echo "⚠ 后端服务可能未正常启动，请查看 backend.log"
fi

cd ..

# 启动前端
echo ""
echo "[3/4] 启动前端服务..."
cd frontend

# 检查node_modules
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖（这可能需要几分钟）..."
    npm install
fi

# 在后台启动前端
echo "启动前端服务 (端口: 8081)..."
npm run serve > ../frontend.log 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > ../frontend.pid

cd ..

# 等待前端启动
sleep 5

echo ""
echo "[4/4] 服务启动完成！"
echo ""
echo "======================================"
echo "服务地址:"
echo "  前端: http://localhost:8081"
echo "  后端: http://localhost:8080"
echo "  健康检查: http://localhost:8080/health"
echo ""
echo "测试URL（带token参数）:"
echo "  http://localhost:8081?token=test_token&userMobile=13800138000&userName=测试用户"
echo ""
echo "查看日志:"
echo "  后端: tail -f backend.log"
echo "  前端: tail -f frontend.log"
echo ""
echo "停止服务:"
echo "  ./stop-local.sh"
echo "======================================"

