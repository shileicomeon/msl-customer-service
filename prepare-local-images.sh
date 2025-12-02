#!/bin/bash

# 准备本地镜像标签脚本
# 用于在无法连接外网时，给本地镜像打上 local- 前缀的标签

echo "======================================"
echo "准备本地镜像标签"
echo "======================================"
echo ""

# 检查并创建 local-node:18-alpine 标签
if docker images | grep -q "local-node:18-alpine"; then
    echo "✓ local-node:18-alpine 已存在"
else
    if docker images | grep -q "node:18-alpine"; then
        echo "为 node:18-alpine 打标签..."
        docker tag node:18-alpine local-node:18-alpine
        echo "✓ 已创建 local-node:18-alpine"
    else
        echo "⚠ 未找到 node:18-alpine 镜像"
    fi
fi

# 检查并创建 local-nginx:alpine 标签
if docker images | grep -q "local-nginx:alpine"; then
    echo "✓ local-nginx:alpine 已存在"
else
    if docker images | grep -q "nginx:alpine"; then
        echo "为 nginx:alpine 打标签..."
        docker tag nginx:alpine local-nginx:alpine
        echo "✓ 已创建 local-nginx:alpine"
    else
        echo "⚠ 未找到 nginx:alpine 镜像"
    fi
fi

# 检查并创建 local-golang:1.21-alpine 标签
if docker images | grep -q "local-golang:1.21-alpine"; then
    echo "✓ local-golang:1.21-alpine 已存在"
else
    if docker images | grep -q "golang:1.21-alpine"; then
        echo "为 golang:1.21-alpine 打标签..."
        docker tag golang:1.21-alpine local-golang:1.21-alpine
        echo "✓ 已创建 local-golang:1.21-alpine"
    else
        echo "⚠ 未找到 golang:1.21-alpine 镜像"
    fi
fi

# 检查并创建 local-alpine:latest 标签
if docker images | grep -q "local-alpine:latest"; then
    echo "✓ local-alpine:latest 已存在"
else
    if docker images | grep -q "alpine:latest"; then
        echo "为 alpine:latest 打标签..."
        docker tag alpine:latest local-alpine:latest
        echo "✓ 已创建 local-alpine:latest"
    else
        echo "⚠ 未找到 alpine:latest 镜像"
    fi
fi

# 检查 Redis 镜像（如果使用 redis:7-alpine 但本地只有 redis:7）
if docker images | grep -q "redis:7-alpine"; then
    echo "✓ redis:7-alpine 已存在"
else
    if docker images | grep -q "redis:7"; then
        echo "为 redis:7 创建 redis:7-alpine 标签..."
        docker tag redis:7 redis:7-alpine
        echo "✓ 已创建 redis:7-alpine"
    else
        echo "⚠ 未找到 redis:7 或 redis:7-alpine 镜像"
    fi
fi

# 确保 Dockerfile 需要的原始镜像标签存在（反向打标签）
echo ""
echo "确保 Dockerfile 需要的镜像标签存在..."

# 从 local-* 标签创建原始标签（如果原始标签不存在）
if docker images | grep -q "local-golang:1.21-alpine" && ! docker images | grep -q "golang:1.21-alpine"; then
    echo "从 local-golang:1.21-alpine 创建 golang:1.21-alpine..."
    docker tag local-golang:1.21-alpine golang:1.21-alpine
    echo "✓ 已创建 golang:1.21-alpine"
fi

if docker images | grep -q "local-node:18-alpine" && ! docker images | grep -q "node:18-alpine"; then
    echo "从 local-node:18-alpine 创建 node:18-alpine..."
    docker tag local-node:18-alpine node:18-alpine
    echo "✓ 已创建 node:18-alpine"
fi

if docker images | grep -q "local-nginx:alpine" && ! docker images | grep -q "nginx:alpine"; then
    echo "从 local-nginx:alpine 创建 nginx:alpine..."
    docker tag local-nginx:alpine nginx:alpine
    echo "✓ 已创建 nginx:alpine"
fi

if docker images | grep -q "local-alpine:latest" && ! docker images | grep -q "alpine:latest"; then
    echo "从 local-alpine:latest 创建 alpine:latest..."
    docker tag local-alpine:latest alpine:latest
    echo "✓ 已创建 alpine:latest"
fi

echo ""
echo "======================================"
echo "镜像标签准备完成！"
echo "======================================"
echo ""
echo "当前本地镜像标签："
docker images | grep -E "local-|node:18-alpine|nginx:alpine|golang:1.21-alpine|alpine:latest" | head -10
echo ""

