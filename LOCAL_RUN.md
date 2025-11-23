# 本地运行指南

## 快速开始

### 1. 配置 MySQL 密码

编辑 `backend/config/config.yaml`，修改数据库密码：

```yaml
database:
  password: "你的MySQL密码" # 修改这里
```

### 2. 创建数据库

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS msl_customer_service CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### 3. 启动服务

```bash
# 方式1: 使用简化脚本（推荐）
./run-local-simple.sh

# 方式2: 使用Docker（如果已安装Docker Desktop）
./run-local.sh
```

### 4. 访问服务

- 前端: http://localhost:8081
- 后端: http://localhost:8080
- 测试 URL: http://localhost:8081?token=test_token&userMobile=13800138000&userName=测试用户

## 停止服务

```bash
./stop-local.sh
```

## 查看日志

```bash
# 后端日志
tail -f backend.log

# 前端日志
tail -f frontend.log
```

## 常见问题

### MySQL 连接失败

1. 检查 MySQL 是否运行: `mysql -u root -p`
2. 检查密码是否正确: 编辑 `backend/config/config.yaml`
3. 检查数据库是否存在: `mysql -u root -p -e "SHOW DATABASES;"`

### 端口被占用

```bash
# 检查端口占用
lsof -i :8080
lsof -i :8081

# 修改端口（编辑配置文件）
```

### 前端依赖安装失败

```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

## 开发模式

### 后端热重载（需要安装 air）

```bash
cd backend
go install github.com/cosmtrek/air@latest
air
```

### 前端热重载

前端已配置热重载，修改代码后自动刷新。
