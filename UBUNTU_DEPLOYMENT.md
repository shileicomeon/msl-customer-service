# Ubuntu 服务器部署指南

## 📋 服务器要求

### 最低配置

- CPU: 2 核
- 内存: 4GB
- 硬盘: 20GB
- 系统: Ubuntu 20.04 LTS 或更高版本

### 推荐配置

- CPU: 4 核
- 内存: 8GB
- 硬盘: 50GB
- 系统: Ubuntu 22.04 LTS

## 🚀 完整部署流程

### 步骤 1: 连接服务器

```bash
# 使用SSH连接到你的Ubuntu服务器
ssh root@your-server-ip

# 或使用普通用户
ssh username@your-server-ip
```

### 步骤 2: 更新系统

```bash
# 更新软件包列表
sudo apt update

# 升级已安装的软件包
sudo apt upgrade -y

# 安装必要的工具
sudo apt install -y curl wget git vim
```

### 步骤 3: 安装 Docker

```bash
# 卸载旧版本（如果有）
sudo apt remove docker docker-engine docker.io containerd runc

# 安装依赖
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加Docker官方GPG密钥
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 设置Docker仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 验证安装
sudo docker --version
sudo docker compose version

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到docker组（可选，避免每次使用sudo）
sudo usermod -aG docker $USER

# 注意：需要重新登录才能生效
# exit 然后重新ssh登录
```

### 步骤 4: 上传项目文件

#### 方式 1: 使用 Git（推荐）

```bash
# 如果项目已经在Git仓库
cd /opt
sudo git clone your-git-repository-url msl-customer-service
cd msl-customer-service
```

#### 方式 2: 使用 SCP 上传

```bash
# 在本地电脑执行（不是在服务器上）
cd /Users/shialei/vueProjectDemo
scp -r msl-customer-service root@your-server-ip:/opt/

# 或者打包后上传
tar -czf msl-customer-service.tar.gz msl-customer-service/
scp msl-customer-service.tar.gz root@your-server-ip:/opt/

# 在服务器上解压
ssh root@your-server-ip
cd /opt
tar -xzf msl-customer-service.tar.gz
cd msl-customer-service
```

#### 方式 3: 使用 SFTP 工具

使用 FileZilla、WinSCP 等工具上传整个项目文件夹到服务器的 `/opt/msl-customer-service`

### 步骤 5: 配置项目

```bash
cd /opt/msl-customer-service

# 1. 修改后端配置
sudo vim backend/config/config.yaml
```

**重要配置项**:

```yaml
server:
  port: 8080
  mode: release # 生产环境使用release模式

database:
  host: mysql # Docker内部使用服务名
  port: 3306
  user: msl_user
  password: YOUR_STRONG_PASSWORD # 修改为强密码
  dbname: msl_customer_service

redis:
  host: redis # Docker内部使用服务名
  port: 6379
  password: ""

jwt:
  secret: YOUR_SECRET_KEY_CHANGE_THIS # 必须修改！使用随机字符串
  expire: 7200

ai:
  provider: openai
  api_key: YOUR_OPENAI_API_KEY # 如果使用AI功能
  model: gpt-3.5-turbo
```

```bash
# 2. 修改Docker Compose配置
sudo vim docker-compose.yml
```

**修改密码**:

```yaml
mysql:
  environment:
    MYSQL_ROOT_PASSWORD: YOUR_STRONG_ROOT_PASSWORD # 修改
    MYSQL_PASSWORD: YOUR_STRONG_PASSWORD # 与config.yaml保持一致
```

```bash
# 3. 给启动脚本添加执行权限
chmod +x start.sh
```

### 步骤 6: 配置防火墙

```bash
# 安装UFW防火墙（如果未安装）
sudo apt install -y ufw

# 允许SSH（重要！避免被锁在外面）
sudo ufw allow 22/tcp

# 允许HTTP和HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status
```

### 步骤 7: 启动服务

```bash
cd /opt/msl-customer-service

# 启动所有服务
sudo docker compose up -d

# 查看启动日志
sudo docker compose logs -f

# 等待所有服务启动（约30秒）
# 按 Ctrl+C 退出日志查看
```

### 步骤 8: 验证服务

```bash
# 1. 检查容器状态
sudo docker compose ps

# 应该看到4个容器都在运行：
# - msl-cs-mysql
# - msl-cs-redis
# - msl-cs-backend
# - msl-cs-frontend

# 2. 测试健康检查
curl http://localhost:8080/health

# 应该返回: {"status":"ok"}

# 3. 测试前端
curl http://localhost

# 应该返回HTML内容
```

### 步骤 9: 配置域名和 HTTPS

#### 9.1 配置域名解析

在你的域名服务商（如阿里云、腾讯云）配置：

- A 记录: `your-domain.com` -> `你的服务器IP`
- A 记录: `www.your-domain.com` -> `你的服务器IP`

#### 9.2 安装 SSL 证书（使用 Let's Encrypt 免费证书）

```bash
# 1. 安装Certbot
sudo apt install -y certbot

# 2. 临时停止前端服务（占用80端口）
cd /opt/msl-customer-service
sudo docker compose stop frontend

# 3. 获取证书
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# 按提示输入邮箱和同意条款
# 证书会保存在 /etc/letsencrypt/live/your-domain.com/

# 4. 修改前端Nginx配置
sudo vim frontend/nginx.conf
```

**添加 HTTPS 配置**:

```nginx
# HTTP重定向到HTTPS
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS配置
server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;

    # SSL证书配置
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # SSL优化
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip压缩
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    # 前端路由
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API代理
    location /api/ {
        proxy_pass http://backend:8080/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 86400;
    }

    # 上传文件
    location /uploads/ {
        proxy_pass http://backend:8080/uploads/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # 缓存静态资源
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

```bash
# 5. 修改docker-compose.yml，挂载证书
sudo vim docker-compose.yml
```

**修改 frontend 服务**:

```yaml
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile
  container_name: msl-cs-frontend
  restart: always
  ports:
    - "80:80"
    - "443:443" # 添加HTTPS端口
  volumes:
    - /etc/letsencrypt:/etc/letsencrypt:ro # 挂载证书
  depends_on:
    - backend
  networks:
    - msl-network
```

```bash
# 6. 重新构建并启动
sudo docker compose build frontend
sudo docker compose up -d

# 7. 设置证书自动续期
sudo crontab -e

# 添加以下行（每月1号凌晨2点续期）
0 2 1 * * certbot renew --quiet && docker compose -f /opt/msl-customer-service/docker-compose.yml restart frontend
```

### 步骤 10: 配置微信小程序业务域名

1. 登录微信公众平台: https://mp.weixin.qq.com
2. 进入"开发" -> "开发管理" -> "开发设置"
3. 找到"业务域名"配置
4. 下载校验文件（如：WxVerifyFile.txt）

```bash
# 5. 上传校验文件到服务器
# 在本地电脑执行
scp WxVerifyFile.txt root@your-server-ip:/opt/msl-customer-service/frontend/public/

# 6. 在服务器上移动文件
ssh root@your-server-ip
sudo mv /opt/msl-customer-service/frontend/public/WxVerifyFile.txt \
        /opt/msl-customer-service/frontend/dist/

# 如果已经构建过，需要重新构建
cd /opt/msl-customer-service
sudo docker compose build frontend
sudo docker compose up -d frontend
```

7. 在微信公众平台输入域名: `your-domain.com`（不带 https://）
8. 点击"保存"

### 步骤 11: 初始化 FAQ 数据

```bash
# 连接到MySQL容器
sudo docker exec -it msl-cs-mysql mysql -u root -p

# 输入密码后，执行
USE msl_customer_service;

# 查看表是否创建成功
SHOW TABLES;

# 检查FAQ数据
SELECT * FROM faqs;

# 如果没有数据，手动导入
exit

# 导入初始化数据
sudo docker exec -i msl-cs-mysql mysql -u root -p msl_customer_service < init.sql
```

## 🔧 常用管理命令

### 服务管理

```bash
# 查看服务状态
cd /opt/msl-customer-service
sudo docker compose ps

# 查看日志
sudo docker compose logs -f [service_name]

# 重启服务
sudo docker compose restart [service_name]

# 停止所有服务
sudo docker compose down

# 启动所有服务
sudo docker compose up -d

# 重新构建并启动
sudo docker compose up -d --build
```

### 数据备份

```bash
# 创建备份目录
sudo mkdir -p /backup/msl-customer-service

# 备份数据库
sudo docker exec msl-cs-mysql mysqldump -u root -p密码 msl_customer_service > /backup/msl-customer-service/db_$(date +%Y%m%d).sql

# 备份上传文件
sudo tar -czf /backup/msl-customer-service/uploads_$(date +%Y%m%d).tar.gz \
    /opt/msl-customer-service/backend/uploads/

# 设置定时备份（每天凌晨3点）
sudo crontab -e
# 添加：
0 3 * * * /opt/msl-customer-service/backup.sh
```

创建备份脚本:

```bash
sudo vim /opt/msl-customer-service/backup.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/backup/msl-customer-service"
DATE=$(date +%Y%m%d)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
docker exec msl-cs-mysql mysqldump -u root -pYOUR_PASSWORD msl_customer_service > $BACKUP_DIR/db_$DATE.sql

# 备份上传文件
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz /opt/msl-customer-service/backend/uploads/

# 删除7天前的备份
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

```bash
sudo chmod +x /opt/msl-customer-service/backup.sh
```

### 监控和日志

```bash
# 查看系统资源使用
htop  # 需要安装: sudo apt install htop

# 查看Docker资源使用
sudo docker stats

# 查看磁盘使用
df -h

# 查看容器日志（实时）
sudo docker compose logs -f --tail=100

# 查看特定服务日志
sudo docker compose logs -f backend
sudo docker compose logs -f frontend
sudo docker compose logs -f mysql

# 清理Docker日志
sudo sh -c "truncate -s 0 /var/lib/docker/containers/*/*-json.log"
```

## 🔍 故障排查

### 问题 1: 容器无法启动

```bash
# 查看详细错误
sudo docker compose logs [service_name]

# 检查配置文件
sudo vim backend/config/config.yaml
sudo vim docker-compose.yml

# 检查端口占用
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :8080
```

### 问题 2: 数据库连接失败

```bash
# 检查MySQL容器状态
sudo docker compose ps mysql

# 进入MySQL容器测试
sudo docker exec -it msl-cs-mysql mysql -u root -p

# 检查网络
sudo docker network ls
sudo docker network inspect msl-customer-service_msl-network
```

### 问题 3: 前端无法访问

```bash
# 检查Nginx配置
sudo docker exec -it msl-cs-frontend cat /etc/nginx/conf.d/default.conf

# 测试Nginx配置
sudo docker exec -it msl-cs-frontend nginx -t

# 查看Nginx日志
sudo docker compose logs frontend
```

### 问题 4: WebSocket 连接失败

```bash
# 检查后端日志
sudo docker compose logs backend | grep -i websocket

# 测试后端连接
curl http://localhost:8080/health

# 检查防火墙
sudo ufw status
```

## 📊 性能优化

### 1. 数据库优化

```bash
# 进入MySQL
sudo docker exec -it msl-cs-mysql mysql -u root -p

# 执行优化
USE msl_customer_service;

# 添加索引
CREATE INDEX idx_user_token ON users(token);
CREATE INDEX idx_conversation_user ON conversations(user_id);
CREATE INDEX idx_message_conversation ON messages(conversation_id);

# 查看索引
SHOW INDEX FROM users;
SHOW INDEX FROM conversations;
SHOW INDEX FROM messages;
```

### 2. Redis 优化

```bash
# 进入Redis
sudo docker exec -it msl-cs-redis redis-cli

# 设置最大内存
CONFIG SET maxmemory 256mb
CONFIG SET maxmemory-policy allkeys-lru

# 查看配置
CONFIG GET maxmemory
CONFIG GET maxmemory-policy
```

### 3. 系统优化

```bash
# 增加文件描述符限制
sudo vim /etc/security/limits.conf

# 添加：
* soft nofile 65535
* hard nofile 65535

# 优化网络参数
sudo vim /etc/sysctl.conf

# 添加：
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_tw_reuse = 1

# 应用配置
sudo sysctl -p
```

## 🔐 安全加固

### 1. 修改 SSH 端口

```bash
sudo vim /etc/ssh/sshd_config

# 修改端口（例如改为2222）
Port 2222

# 禁止root登录
PermitRootLogin no

# 重启SSH服务
sudo systemctl restart sshd

# 更新防火墙
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
```

### 2. 配置 Fail2ban

```bash
# 安装Fail2ban
sudo apt install -y fail2ban

# 创建配置
sudo vim /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
```

```bash
# 启动服务
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

### 3. 定期更新

```bash
# 创建更新脚本
sudo vim /opt/update.sh
```

```bash
#!/bin/bash
apt update
apt upgrade -y
apt autoremove -y
docker system prune -af
```

```bash
sudo chmod +x /opt/update.sh

# 设置每周日凌晨4点自动更新
sudo crontab -e
# 添加：
0 4 * * 0 /opt/update.sh
```

## ✅ 部署检查清单

- [ ] 服务器已更新到最新
- [ ] Docker 和 Docker Compose 已安装
- [ ] 项目文件已上传
- [ ] 配置文件已修改（密码、密钥）
- [ ] 防火墙已配置
- [ ] 服务已启动
- [ ] 健康检查通过
- [ ] 域名已解析
- [ ] SSL 证书已配置
- [ ] 微信业务域名已配置
- [ ] 备份脚本已设置
- [ ] 监控已配置

## 🎉 完成！

现在你的智能客服系统已经在 Ubuntu 服务器上运行了！

访问: `https://your-domain.com`

如有问题，查看日志: `sudo docker compose logs -f`
