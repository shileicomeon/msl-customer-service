#!/bin/bash

# 简化的本地开发启动脚本（不使用Docker）

echo "======================================"
echo "马上来智能客服系统 - 本地开发环境"
echo "======================================"
echo ""

cd "$(dirname "$0")"

# 检查Go
if ! command -v go &> /dev/null; then
    echo "错误: Go未安装"
    exit 1
fi

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo "错误: Node.js未安装"
    exit 1
fi

# 检查MySQL
if ! command -v mysql &> /dev/null; then
    echo "警告: MySQL未在PATH中找到，请确保MySQL已安装并运行"
fi

# 创建数据库（如果不存在）
echo "[1/5] 检查数据库..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS msl_customer_service CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || {
    echo "⚠ 无法自动创建数据库，请手动创建:"
    echo "  mysql -u root -e \"CREATE DATABASE msl_customer_service CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""
}

# 安装Go依赖
echo "[2/5] 安装Go依赖..."
cd backend
go mod download
cd ..

# 创建上传目录
mkdir -p backend/uploads

# 启动后端
echo "[3/5] 启动后端服务 (端口: 8080)..."
cd backend
go run main.go > ../backend.log 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > ../backend.pid
cd ..

# 等待后端启动
sleep 3

# 检查后端
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✓ 后端服务已启动"
else
    echo "⚠ 后端服务可能未正常启动，请查看 backend.log"
    echo "  提示: 请确保MySQL已启动，并且config.yaml中的密码正确"
fi

# 安装前端依赖
echo ""
echo "[4/5] 检查前端依赖..."
cd frontend
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖（这可能需要几分钟）..."
    npm install
fi
cd ..

# 启动前端
echo ""
echo "[5/5] 启动前端服务 (端口: 8081)..."
cd frontend
npm run serve > ../frontend.log 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > ../frontend.pid
cd ..

# 等待前端启动
sleep 5

echo ""
echo "======================================"
echo "服务启动完成！"
echo "======================================"
echo ""
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
echo "  ./stop-local.sh 或 kill \$(cat backend.pid frontend.pid)"
echo ""
echo "注意:"
echo "  - 请确保MySQL已启动"
echo "  - 请检查 backend/config/config.yaml 中的数据库密码"
echo "  - Redis是可选的，未安装也能运行"
echo "======================================"

