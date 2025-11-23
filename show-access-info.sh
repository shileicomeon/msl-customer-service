#!/bin/bash

echo "======================================"
echo "马上来智能客服系统 - 访问信息"
echo "======================================"
echo ""

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# 如果无法获取，尝试其他方法
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip route get 8.8.8.8 | awk '{print $7; exit}')
fi

# 如果还是无法获取，使用localhost
if [ -z "$SERVER_IP" ]; then
    SERVER_IP="localhost"
fi

echo "服务器IP地址: $SERVER_IP"
echo ""
echo "浏览器访问地址："
echo "  📱 前端应用: http://$SERVER_IP"
echo "  🔧 后端API:  http://$SERVER_IP:8080"
echo "  ❤️  健康检查: http://$SERVER_IP:8080/health"
echo ""
echo "如果配置了域名，请使用域名访问"
echo ""
echo "服务状态："
docker compose ps 2>/dev/null || docker-compose ps 2>/dev/null || echo "  请先启动服务: docker compose up -d"
echo ""

