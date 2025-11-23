#!/bin/bash

# 停止本地开发环境

echo "停止本地开发服务..."

cd "$(dirname "$0")"

# 停止后端
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "停止后端服务 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID
        rm backend.pid
    fi
fi

# 停止前端
if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "停止前端服务 (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID
        rm frontend.pid
    fi
fi

# 停止Docker容器
echo "停止MySQL和Redis..."
docker compose stop mysql redis

echo "所有服务已停止"

