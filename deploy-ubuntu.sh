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

# 步骤8: 拉取镜像
echo -e "${GREEN}[8/10] 拉取Docker镜像...${NC}"
docker compose pull

# 步骤9: 构建并启动服务
echo -e "${GREEN}[9/10] 构建并启动服务...${NC}"
docker compose up -d --build

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

