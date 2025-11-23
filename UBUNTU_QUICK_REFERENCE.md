# Ubuntu 服务器快速参考

## 🚀 一键部署（最简单）

```bash
# 1. 上传项目到服务器
scp -r msl-customer-service root@your-server-ip:/opt/

# 2. SSH连接到服务器
ssh root@your-server-ip

# 3. 修改配置
cd /opt/msl-customer-service
vim backend/config/config.yaml  # 修改密码和密钥
vim docker-compose.yml          # 修改MySQL密码

# 4. 运行自动部署脚本
sudo bash deploy-ubuntu.sh

# 完成！访问 http://your-server-ip
```

## 📋 手动部署步骤

### 1. 安装 Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. 上传项目

```bash
# 本地执行
cd /Users/shialei/vueProjectDemo
scp -r msl-customer-service root@your-server-ip:/opt/
```

### 3. 配置并启动

```bash
# 服务器执行
cd /opt/msl-customer-service
vim backend/config/config.yaml  # 修改配置
./start.sh                       # 启动服务
```

## 🔧 常用命令速查

### 服务管理

```bash
cd /opt/msl-customer-service

# 启动
docker compose up -d

# 停止
docker compose down

# 重启
docker compose restart

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 配置 HTTPS

```bash
# 1. 停止前端
docker compose stop frontend

# 2. 获取证书
certbot certonly --standalone -d your-domain.com

# 3. 修改nginx配置（见UBUNTU_DEPLOYMENT.md）
vim frontend/nginx.conf

# 4. 修改docker-compose.yml挂载证书
vim docker-compose.yml

# 5. 重启
docker compose up -d --build
```

### 数据备份

```bash
# 手动备份
docker exec msl-cs-mysql mysqldump -u root -p密码 msl_customer_service > backup.sql

# 自动备份（已配置）
/opt/msl-customer-service/backup.sh
```

### 查看日志

```bash
# 所有日志
docker compose logs -f

# 特定服务
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f mysql
```

## 🔍 故障排查

### 服务无法启动

```bash
# 查看错误
docker compose logs [service_name]

# 检查端口
netstat -tlnp | grep :80
netstat -tlnp | grep :8080

# 重启Docker
systemctl restart docker
```

### 数据库连接失败

```bash
# 进入MySQL
docker exec -it msl-cs-mysql mysql -u root -p

# 检查配置
cat backend/config/config.yaml
```

### 前端无法访问

```bash
# 检查防火墙
ufw status
ufw allow 80/tcp

# 测试Nginx
docker exec -it msl-cs-frontend nginx -t
```

## 📱 小程序配置

### 1. 业务域名

- 登录: https://mp.weixin.qq.com
- 路径: 开发 -> 开发管理 -> 开发设置 -> 业务域名
- 下载校验文件上传到: `/opt/msl-customer-service/frontend/public/`

### 2. 小程序代码

```typescript
// pages/mine/mine.ts
onCustomerService() {
  const token = wx.getStorageSync("token");
  const { userMobile, userName } = this.data.userInfo;
  wx.navigateTo({
    url: `/pages/customer-service/index?token=${token}&userMobile=${userMobile}&userName=${userName}`,
  });
}
```

## 🔐 安全检查清单

- [ ] 修改所有默认密码
- [ ] 修改 JWT 密钥
- [ ] 配置 HTTPS
- [ ] 配置防火墙
- [ ] 设置自动备份
- [ ] 禁用 root SSH 登录（可选）

## 📊 监控命令

```bash
# 系统资源
htop

# Docker资源
docker stats

# 磁盘使用
df -h

# 服务状态
systemctl status docker
docker compose ps
```

## 🆘 紧急情况

### 服务崩溃

```bash
cd /opt/msl-customer-service
docker compose down
docker compose up -d
```

### 数据库损坏

```bash
# 恢复备份
docker exec -i msl-cs-mysql mysql -u root -p msl_customer_service < /backup/msl-customer-service/db_YYYYMMDD.sql
```

### 磁盘满了

```bash
# 清理Docker
docker system prune -af

# 清理日志
journalctl --vacuum-time=3d

# 清理备份
rm -f /backup/msl-customer-service/db_*.sql
```

## 📞 获取帮助

- 完整文档: `UBUNTU_DEPLOYMENT.md`
- 项目文档: `README.md`
- 快速开始: `QUICK_START.md`

## 🎯 性能优化

```bash
# 数据库索引
docker exec -it msl-cs-mysql mysql -u root -p
USE msl_customer_service;
CREATE INDEX idx_user_token ON users(token);

# Redis配置
docker exec -it msl-cs-redis redis-cli
CONFIG SET maxmemory 256mb
```

## ✅ 部署后验证

```bash
# 1. 检查服务
docker compose ps

# 2. 测试后端
curl http://localhost:8080/health

# 3. 测试前端
curl http://localhost

# 4. 测试WebSocket（需要工具）
# wscat -c ws://localhost:8080/api/ws?token=xxx
```

---

**提示**: 将此文件保存到服务器上，随时查阅！
