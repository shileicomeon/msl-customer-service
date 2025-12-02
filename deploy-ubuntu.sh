#!/bin/bash

# 马上来智能客服系统 - Ubuntu自动部署脚本
# 使用方法: sudo bash deploy-ubuntu.sh

set -e

echo "======================================"
echo "马上来智能客服系统 - Ubuntu部署脚本"
echo "======================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}错误: 请使用root权限运行此脚本${NC}"
    echo "使用: sudo bash deploy-ubuntu.sh"
    exit 1
fi

# 步骤1: 更新系统
echo -e "${GREEN}[1/10] 更新系统...${NC}"
apt update
apt upgrade -y
apt install -y curl wget git vim htop

# 步骤2: 检查Docker
echo -e "${GREEN}[2/10] 检查Docker安装...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Docker未安装，开始安装..."
    
    # 安装依赖
    apt install -y ca-certificates curl gnupg lsb-release
    
    # 添加Docker GPG密钥
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # 设置Docker仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 启动Docker
    systemctl start docker
    systemctl enable docker
    
    echo -e "${GREEN}Docker安装完成${NC}"
else
    echo -e "${GREEN}Docker已安装: $(docker --version)${NC}"
fi

# 检查Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}错误: Docker Compose未安装${NC}"
    exit 1
fi

# 步骤3: 配置防火墙
echo -e "${GREEN}[3/10] 配置防火墙...${NC}"
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo -e "${GREEN}防火墙配置完成${NC}"
else
    echo -e "${YELLOW}警告: UFW未安装，跳过防火墙配置${NC}"
fi

# 步骤4: 检查项目目录
echo -e "${GREEN}[4/10] 检查项目目录...${NC}"
PROJECT_DIR="/opt/msl-customer-service"

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}错误: 项目目录不存在: $PROJECT_DIR${NC}"
    echo "请先上传项目文件到服务器"
    exit 1
fi

cd $PROJECT_DIR

# 步骤5: 检查配置文件
echo -e "${GREEN}[5/10] 检查配置文件...${NC}"

if [ ! -f "backend/config/config.yaml" ]; then
    echo -e "${RED}错误: 配置文件不存在: backend/config/config.yaml${NC}"
    exit 1
fi

if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}错误: Docker Compose配置不存在${NC}"
    exit 1
fi

# 检查是否修改了默认密码
if grep -q "your_password" backend/config/config.yaml; then
    echo -e "${YELLOW}警告: 检测到默认密码，请修改 backend/config/config.yaml${NC}"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 步骤6: 创建必要的目录
echo -e "${GREEN}[6/10] 创建必要的目录...${NC}"
mkdir -p backend/uploads
mkdir -p /backup/msl-customer-service
chmod +x start.sh 2>/dev/null || true

# 步骤7: 停止旧服务
echo -e "${GREEN}[7/10] 停止旧服务...${NC}"
docker compose down 2>/dev/null || true

# 步骤8: 准备本地镜像标签
echo -e "${GREEN}[8/10] 准备本地镜像标签...${NC}"
echo "跳过拉取镜像（使用本地镜像）"

echo "为 Dockerfile 准备镜像标签..."

# 1. 确保 Dockerfile 使用的原始镜像标签存在
# golang:1.21-alpine (Dockerfile 需要)
if ! docker images | grep -q "golang:1.21-alpine"; then
    if docker images | grep -q "local-golang:1.21-alpine"; then
        echo "从 local-golang:1.21-alpine 创建 golang:1.21-alpine..."
        docker tag local-golang:1.21-alpine golang:1.21-alpine 2>/dev/null || true
    fi
fi

# node:18-alpine (Dockerfile 需要)
if ! docker images | grep -q "node:18-alpine"; then
    if docker images | grep -q "local-node:18-alpine"; then
        echo "从 local-node:18-alpine 创建 node:18-alpine..."
        docker tag local-node:18-alpine node:18-alpine 2>/dev/null || true
    fi
fi

# nginx:alpine (Dockerfile 需要)
if ! docker images | grep -q "nginx:alpine"; then
    if docker images | grep -q "local-nginx:alpine"; then
        echo "从 local-nginx:alpine 创建 nginx:alpine..."
        docker tag local-nginx:alpine nginx:alpine 2>/dev/null || true
    fi
fi

# alpine:latest (Dockerfile 需要)
if ! docker images | grep -q "alpine:latest"; then
    if docker images | grep -q "local-alpine:latest"; then
        echo "从 local-alpine:latest 创建 alpine:latest..."
        docker tag local-alpine:latest alpine:latest 2>/dev/null || true
    fi
fi

# redis:7-alpine (docker-compose.yml 需要，但本地只有 redis:7)
if ! docker images | grep -q "redis:7-alpine"; then
    if docker images | grep -q "redis:7"; then
        echo "从 redis:7 创建 redis:7-alpine..."
        docker tag redis:7 redis:7-alpine 2>/dev/null || true
    fi
fi

# 2. 同时创建 local- 前缀的标签（用于后续使用）
if docker images | grep -q "node:18-alpine" && ! docker images | grep -q "local-node:18-alpine"; then
    docker tag node:18-alpine local-node:18-alpine 2>/dev/null || true
fi
if docker images | grep -q "nginx:alpine" && ! docker images | grep -q "local-nginx:alpine"; then
    docker tag nginx:alpine local-nginx:alpine 2>/dev/null || true
fi
if docker images | grep -q "golang:1.21-alpine" && ! docker images | grep -q "local-golang:1.21-alpine"; then
    docker tag golang:1.21-alpine local-golang:1.21-alpine 2>/dev/null || true
fi
if docker images | grep -q "alpine:latest" && ! docker images | grep -q "local-alpine:latest"; then
    docker tag alpine:latest local-alpine:latest 2>/dev/null || true
fi

echo "✓ 镜像标签准备完成"

# 步骤9: 验证镜像并构建服务
echo -e "${GREEN}[9/10] 构建并启动服务...${NC}"

# 验证所有必需的镜像是否存在
echo "验证必需的镜像..."
REQUIRED_IMAGES=("golang:1.21-alpine" "node:18-alpine" "nginx:alpine" "alpine:latest" "redis:7" "mysql:8.0")
MISSING_IMAGES=()

for img in "${REQUIRED_IMAGES[@]}"; do
    if ! docker images | grep -q "$img"; then
        MISSING_IMAGES+=("$img")
    fi
done

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    echo -e "${RED}错误: 以下镜像不存在，无法继续构建:${NC}"
    for img in "${MISSING_IMAGES[@]}"; do
        echo "  - $img"
    done
    echo ""
    echo "请先导入这些镜像或运行 prepare-local-images.sh 准备镜像标签"
    exit 1
fi

echo "✓ 所有必需镜像已就绪"

# 预热镜像（让 Docker 完全识别镜像，避免构建时尝试验证 digest）
echo "预热镜像（确保 Docker 完全识别）..."
BUILD_IMAGES=("golang:1.21-alpine" "node:18-alpine" "nginx:alpine" "alpine:latest")
for img in "${BUILD_IMAGES[@]}"; do
    echo "  验证 $img..."
    # 使用 docker inspect 确保镜像元数据已加载
    INSPECT_OUTPUT=$(docker inspect "$img" 2>&1)
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 镜像 $img 无法访问${NC}"
        echo "$INSPECT_OUTPUT"
        exit 1
    fi
    # 获取镜像 ID 并验证
    IMAGE_ID=$(echo "$INSPECT_OUTPUT" | grep -i "Id" | head -1 | awk '{print $2}' | tr -d '",')
    if [ -z "$IMAGE_ID" ]; then
        IMAGE_ID=$(docker images "$img" --format "{{.ID}}" | head -1)
    fi
    echo "    镜像 ID: $IMAGE_ID"
done
echo "✓ 所有构建镜像已验证"

# 使用 --pull=false 确保不尝试从远程拉取，禁用 BuildKit 避免元数据检查
export DOCKER_BUILDKIT=0
export COMPOSE_DOCKER_CLI_BUILD=0

# 构建服务（使用 docker build 直接构建，避免 compose 的额外检查）
echo "开始构建（离线模式）..."
cd $PROJECT_DIR

# 先构建后端
echo "构建后端服务..."
cd backend

# 确保原始标签存在（从 local-* 标签创建，如果不存在）
if ! docker images | grep -q "golang:1.21-alpine"; then
    if docker images | grep -q "local-golang:1.21-alpine"; then
        echo "  创建 golang:1.21-alpine 标签..."
        docker tag local-golang:1.21-alpine golang:1.21-alpine
    fi
fi
if ! docker images | grep -q "alpine:latest"; then
    if docker images | grep -q "local-alpine:latest"; then
        echo "  创建 alpine:latest 标签..."
        docker tag local-alpine:latest alpine:latest
    fi
fi

# 创建临时 Dockerfile（使用原始标签，不使用 local-*）
cat > Dockerfile.build << 'EOF'
# 构建阶段
FROM golang:1.21-alpine AS builder

WORKDIR /app

# 复制go mod文件
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# 运行阶段
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# 从构建阶段复制二进制文件
COPY --from=builder /app/main .
COPY --from=builder /app/config ./config

# 创建上传目录
RUN mkdir -p ./uploads

# 设置时区
ENV TZ=Asia/Shanghai

EXPOSE 8080

CMD ["./main"]
EOF

# 使用临时 Dockerfile 构建
echo "  使用原始标签构建..."
DOCKER_BUILDKIT=0 docker build --pull=false -f Dockerfile.build -t local-backend:latest . 2>&1 | grep -v "WARN" | grep -v "Docker Compose" | grep -v "DEPRECATED" || {
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ 后端构建完成${NC}"
    else
        echo -e "${RED}✗ 后端构建失败，退出码: $BUILD_EXIT_CODE${NC}"
        echo "提示: 请确保所有基础镜像都已正确加载"
        echo "尝试解决方案:"
        echo "  1. 检查镜像: docker images | grep -E 'golang|alpine'"
        echo "  2. 重新加载镜像: docker load < image.tar"
        exit 1
    fi
}

# 清理临时文件
rm -f Dockerfile.build
cd ..

# 再构建前端
echo "构建前端服务..."
cd frontend

# 确保原始标签存在（从 local-* 标签创建，如果不存在）
if ! docker images | grep -q "node:18-alpine"; then
    if docker images | grep -q "local-node:18-alpine"; then
        echo "  创建 node:18-alpine 标签..."
        docker tag local-node:18-alpine node:18-alpine
    fi
fi
if ! docker images | grep -q "nginx:alpine"; then
    if docker images | grep -q "local-nginx:alpine"; then
        echo "  创建 nginx:alpine 标签..."
        docker tag local-nginx:alpine nginx:alpine
    fi
fi

# 创建临时 Dockerfile（使用原始标签，不使用 local-*）
cat > Dockerfile.build << 'EOF'
# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm install --registry=https://registry.npmmirror.com

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 运行阶段
FROM nginx:alpine

# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html

# 复制nginx配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOF

# 使用临时 Dockerfile 构建
echo "  使用原始标签构建..."
DOCKER_BUILDKIT=0 docker build --pull=false -f Dockerfile.build -t local-frontend:latest . 2>&1 | grep -v "WARN" | grep -v "Docker Compose" | grep -v "DEPRECATED" || {
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
    if [ $BUILD_EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✓ 前端构建完成${NC}"
    else
        echo -e "${RED}✗ 前端构建失败，退出码: $BUILD_EXIT_CODE${NC}"
        echo "提示: 请确保所有基础镜像都已正确加载"
        echo "尝试解决方案:"
        echo "  1. 检查镜像: docker images | grep -E 'node|nginx'"
        echo "  2. 重新加载镜像: docker load < image.tar"
        exit 1
    fi
}

# 清理临时文件
rm -f Dockerfile.build
cd ..

# 启动服务
echo "启动服务..."
docker compose up -d

# 等待服务启动
echo "等待服务启动..."
sleep 15

# 步骤10: 验证服务
echo -e "${GREEN}[10/10] 验证服务状态...${NC}"

# 检查容器状态
echo ""
echo "容器状态:"
docker compose ps

# 检查健康状态
echo ""
echo "健康检查:"
if curl -s http://localhost:8080/health | grep -q "ok"; then
    echo -e "${GREEN}✓ 后端服务正常${NC}"
else
    echo -e "${RED}✗ 后端服务异常${NC}"
fi

if curl -s http://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 前端服务正常${NC}"
else
    echo -e "${RED}✗ 前端服务异常${NC}"
fi

# 创建备份脚本
echo ""
echo "创建备份脚本..."
cat > /opt/msl-customer-service/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup/msl-customer-service"
DATE=$(date +%Y%m%d)
PROJECT_DIR="/opt/msl-customer-service"

mkdir -p $BACKUP_DIR

# 从docker-compose.yml读取密码
cd $PROJECT_DIR
DB_PASSWORD=$(grep MYSQL_ROOT_PASSWORD docker-compose.yml | head -1 | awk '{print $2}')

# 备份数据库
docker exec msl-cs-mysql mysqldump -u root -p$DB_PASSWORD msl_customer_service > $BACKUP_DIR/db_$DATE.sql

# 备份上传文件
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz $PROJECT_DIR/backend/uploads/

# 删除7天前的备份
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/msl-customer-service/backup.sh

# 设置定时任务
echo "配置定时任务..."
(crontab -l 2>/dev/null | grep -v "msl-customer-service"; echo "0 3 * * * /opt/msl-customer-service/backup.sh >> /var/log/msl-backup.log 2>&1") | crontab -

echo ""
echo "======================================"
echo -e "${GREEN}部署完成！${NC}"
echo "======================================"
echo ""
echo "服务信息:"
echo "  前端地址: http://$(hostname -I | awk '{print $1}')"
echo "  后端地址: http://$(hostname -I | awk '{print $1}'):8080"
echo "  健康检查: http://$(hostname -I | awk '{print $1}'):8080/health"
echo ""
echo "管理命令:"
echo "  查看日志: cd $PROJECT_DIR && docker compose logs -f"
echo "  重启服务: cd $PROJECT_DIR && docker compose restart"
echo "  停止服务: cd $PROJECT_DIR && docker compose down"
echo ""
echo "下一步:"
echo "  1. 配置域名解析"
echo "  2. 安装SSL证书（使用 certbot）"
echo "  3. 配置微信业务域名"
echo "  4. 在小程序中集成客服入口"
echo ""
echo "详细文档: $PROJECT_DIR/UBUNTU_DEPLOYMENT.md"
echo ""

