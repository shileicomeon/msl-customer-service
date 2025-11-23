# 快速开始指南

## 🚀 5 分钟快速部署

### 前置要求

- Docker & Docker Compose 已安装
- 服务器已开放 80 和 8080 端口

### 步骤 1: 修改配置

```bash
cd /Users/shialei/vueProjectDemo/msl-customer-service

# 修改数据库密码
vim docker-compose.yml
# 修改 MYSQL_ROOT_PASSWORD 和 MYSQL_PASSWORD

# 修改后端配置
vim backend/config/config.yaml
# 修改 database.password 和 jwt.secret
```

### 步骤 2: 启动服务

```bash
# 方式1: 使用启动脚本（推荐）
./start.sh

# 方式2: 手动启动
docker-compose up -d
```

### 步骤 3: 验证服务

```bash
# 检查服务状态
docker-compose ps

# 访问健康检查
curl http://localhost:8080/health

# 查看日志
docker-compose logs -f
```

### 步骤 4: 访问系统

- 前端: http://localhost
- 后端: http://localhost:8080

## 📱 小程序集成

### 1. 添加客服入口（mine.wxml）

```xml
<view class="menu-item" bindtap="onCustomerService">
  <van-icon name="service-o" size="20px" />
  <text>智能客服</text>
</view>
```

### 2. 添加跳转方法（mine.ts）

```typescript
onCustomerService() {
  const token = wx.getStorageSync("token");
  const { userMobile, userName } = this.data.userInfo;

  wx.navigateTo({
    url: `/pages/customer-service/index?token=${token}&userMobile=${userMobile}&userName=${userName}`,
  });
}
```

### 3. 创建客服页面

创建 `pages/customer-service/` 目录，包含：

- index.wxml: `<web-view src="{{webviewUrl}}"></web-view>`
- index.ts: 处理 URL 参数
- index.json: 页面配置

详细代码请参考: `miniprogram-integration-example.md`

### 4. 配置业务域名

1. 登录微信公众平台
2. 开发 -> 开发管理 -> 开发设置 -> 业务域名
3. 下载校验文件并上传到服务器根目录
4. 添加域名（不带协议）

## 🔧 常用命令

### Docker 管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f [service_name]

# 进入容器
docker exec -it msl-cs-backend sh
```

### 数据库管理

```bash
# 备份数据库
docker exec msl-cs-mysql mysqldump -u root -p msl_customer_service > backup.sql

# 恢复数据库
docker exec -i msl-cs-mysql mysql -u root -p msl_customer_service < backup.sql

# 连接数据库
docker exec -it msl-cs-mysql mysql -u root -p
```

### 查看状态

```bash
# 查看容器状态
docker-compose ps

# 查看资源使用
docker stats

# 查看网络
docker network ls
```

## 🐛 故障排查

### 问题 1: 容器启动失败

```bash
# 查看详细日志
docker-compose logs [service_name]

# 检查配置文件
vim backend/config/config.yaml
vim docker-compose.yml
```

### 问题 2: 数据库连接失败

```bash
# 检查MySQL是否启动
docker-compose ps mysql

# 查看MySQL日志
docker-compose logs mysql

# 测试连接
docker exec -it msl-cs-mysql mysql -u root -p
```

### 问题 3: WebSocket 连接失败

```bash
# 检查后端日志
docker-compose logs backend

# 检查防火墙
sudo ufw status

# 测试端口
telnet localhost 8080
```

### 问题 4: 前端无法访问

```bash
# 检查Nginx日志
docker-compose logs frontend

# 检查端口占用
netstat -tlnp | grep 80

# 重启前端服务
docker-compose restart frontend
```

## 📊 监控和维护

### 日常检查

```bash
# 每日健康检查
curl http://localhost:8080/health

# 查看容器状态
docker-compose ps

# 查看磁盘使用
df -h
```

### 定期维护

```bash
# 每周备份数据
./backup.sh

# 每月清理日志
docker system prune -a

# 每季度更新镜像
docker-compose pull
docker-compose up -d
```

## 🔐 安全配置

### 生产环境必做

1. **修改所有默认密码**

   - MySQL root 密码
   - MySQL 用户密码
   - JWT 密钥

2. **配置 HTTPS**

   ```bash
   # 安装certbot
   apt install certbot

   # 获取证书
   certbot certonly --standalone -d your-domain.com
   ```

3. **配置防火墙**

   ```bash
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```

4. **限制访问**
   - 修改数据库端口（不对外开放）
   - 配置 Redis 密码
   - 添加访问频率限制

## 📈 性能优化

### 数据库优化

```sql
-- 添加索引
CREATE INDEX idx_user_token ON users(token);
CREATE INDEX idx_conversation_user ON conversations(user_id);
CREATE INDEX idx_message_conversation ON messages(conversation_id);

-- 定期清理旧数据
DELETE FROM messages WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);
```

### Redis 缓存

```bash
# 配置Redis最大内存
docker exec -it msl-cs-redis redis-cli CONFIG SET maxmemory 256mb
docker exec -it msl-cs-redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

### Nginx 优化

在 `frontend/nginx.conf` 中添加：

```nginx
# 开启gzip压缩
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;

# 开启缓存
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m;
```

## 🔄 更新升级

### 更新代码

```bash
# 拉取最新代码
git pull

# 重新构建
docker-compose build

# 重启服务
docker-compose up -d
```

### 数据迁移

```bash
# 备份当前数据
./backup.sh

# 执行迁移脚本
docker exec -it msl-cs-backend ./migrate

# 验证数据
docker exec -it msl-cs-mysql mysql -u root -p -e "USE msl_customer_service; SHOW TABLES;"
```

## 📞 获取帮助

### 文档

- README.md - 完整文档
- PROJECT_OVERVIEW.md - 项目总览
- miniprogram-integration-example.md - 小程序集成

### 日志位置

- 后端日志: `docker-compose logs backend`
- 前端日志: `docker-compose logs frontend`
- MySQL 日志: `docker-compose logs mysql`
- Redis 日志: `docker-compose logs redis`

### 常见问题

查看 README.md 中的"常见问题"章节

## ✅ 检查清单

### 部署前

- [ ] 修改所有默认密码
- [ ] 配置 JWT 密钥
- [ ] 配置 OpenAI API Key（如使用）
- [ ] 检查服务器配置
- [ ] 备份重要数据

### 部署后

- [ ] 验证健康检查
- [ ] 测试 WebSocket 连接
- [ ] 测试聊天功能
- [ ] 测试文件上传
- [ ] 测试 FAQ 功能
- [ ] 配置监控告警

### 小程序集成后

- [ ] 测试客服入口
- [ ] 测试 token 传递
- [ ] 测试聊天功能
- [ ] 测试移动端适配
- [ ] 配置业务域名
- [ ] 真机测试

## 🎉 完成！

现在你的智能客服系统已经运行起来了！

- 访问 http://localhost 查看前端
- 在小程序中点击"智能客服"开始使用
- 查看日志监控系统运行状态

有问题？查看完整文档或联系技术支持。
