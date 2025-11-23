# 马上来场站服务系统 - 智能客服系统

## 项目简介

这是一个为马上来场站服务系统开发的智能客服系统，支持实时聊天、AI智能回复、常见问题查询、文件上传等功能。系统采用前后端分离架构，兼容手机和电脑端。

## 技术栈

### 后端
- Go 1.21
- Gin (Web框架)
- GORM (ORM)
- WebSocket (实时通信)
- MySQL 8.0
- Redis
- JWT (认证)

### 前端
- Vue 3
- Element Plus
- Pinia (状态管理)
- Axios
- WebSocket

## 项目结构

```
msl-customer-service/
├── backend/                 # 后端Go项目
│   ├── config/             # 配置文件
│   ├── internal/           # 内部代码
│   │   ├── database/       # 数据库连接
│   │   ├── handler/        # 请求处理器
│   │   ├── middleware/     # 中间件
│   │   ├── models/         # 数据模型
│   │   ├── router/         # 路由
│   │   └── service/        # 业务逻辑
│   ├── main.go            # 入口文件
│   ├── go.mod             # Go依赖
│   └── Dockerfile         # Docker配置
├── frontend/               # 前端Vue项目
│   ├── public/            # 静态资源
│   ├── src/
│   │   ├── api/           # API接口
│   │   ├── router/        # 路由
│   │   ├── stores/        # 状态管理
│   │   ├── styles/        # 样式
│   │   ├── utils/         # 工具函数
│   │   ├── views/         # 页面组件
│   │   ├── App.vue        # 根组件
│   │   └── main.js        # 入口文件
│   ├── package.json       # npm依赖
│   ├── nginx.conf         # Nginx配置
│   └── Dockerfile         # Docker配置
├── docker-compose.yml      # Docker Compose配置
├── init.sql               # 数据库初始化脚本
└── README.md              # 项目文档
```

## 功能特性

### 1. 用户认证
- 基于小程序token的无缝认证
- 自动创建/更新用户信息
- 会话管理

### 2. 实时聊天
- WebSocket实时通信
- 消息自动重连
- 心跳检测
- 输入状态提示

### 3. AI智能客服
- 集成OpenAI API
- FAQ智能匹配
- 上下文理解
- 自定义回复策略

### 4. 常见问题
- FAQ分类管理
- 关键词搜索
- 查看次数统计

### 5. 文件上传
- 图片上传
- 文件类型限制
- 大小限制
- 安全验证

### 6. 用户反馈
- 满意度评分
- 文字反馈
- 反馈统计

### 7. 响应式设计
- 移动端适配
- PC端优化
- 自适应布局

## 快速开始

### 开发环境要求

- Go 1.21+
- Node.js 18+
- MySQL 8.0+
- Redis 7+
- Docker & Docker Compose (可选)

### 本地开发

#### 1. 克隆项目

```bash
cd /Users/shialei/vueProjectDemo/msl-customer-service
```

#### 2. 配置后端

```bash
cd backend

# 修改配置文件
vim config/config.yaml

# 配置数据库连接、Redis、AI API Key等

# 安装依赖
go mod download

# 运行
go run main.go
```

#### 3. 配置前端

```bash
cd frontend

# 安装依赖
npm install

# 运行开发服务器
npm run serve

# 访问 http://localhost:8081
```

### Docker部署

#### 1. 修改配置

```bash
# 修改docker-compose.yml中的密码等配置
vim docker-compose.yml

# 修改backend/config/config.yaml
vim backend/config/config.yaml
```

#### 2. 启动服务

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

#### 3. 访问服务

- 前端：http://your-server-ip
- 后端API：http://your-server-ip:8080
- 健康检查：http://your-server-ip:8080/health

## 小程序集成

### 1. 在小程序中添加客服入口

在 `miniprogram/pages/mine/mine.wxml` 中添加客服按钮：

```xml
<view class="menu-item" bindtap="onCustomerService">
  <van-icon name="service-o" size="20px" />
  <text>智能客服</text>
  <van-icon name="arrow" />
</view>
```

### 2. 在 `mine.ts` 中添加处理函数

```typescript
onCustomerService() {
  if (this.data.userInfo == null) {
    wx.navigateTo({
      url: "/userPages/pages/login-method/login-method",
    });
    return;
  }

  const token = wx.getStorageSync("token");
  const userMobile = this.data.userInfo.userMobile;
  const userName = this.data.userInfo.userName;

  // 跳转到客服页面
  wx.navigateTo({
    url: `/pages/customer-service/index?token=${token}&userMobile=${userMobile}&userName=${userName}`,
  });
},
```

### 3. 创建客服页面

在 `miniprogram/pages/customer-service/` 目录下创建页面：

**index.wxml:**
```xml
<web-view src="{{webviewUrl}}"></web-view>
```

**index.ts:**
```typescript
Page({
  data: {
    webviewUrl: ''
  },

  onLoad(options: any) {
    const { token, userMobile, userName } = options;
    // 替换为你的实际域名
    const baseUrl = 'https://your-domain.com';
    const url = `${baseUrl}?token=${token}&userMobile=${encodeURIComponent(userMobile)}&userName=${encodeURIComponent(userName)}`;
    
    this.setData({
      webviewUrl: url
    });
  }
});
```

**index.json:**
```json
{
  "navigationBarTitleText": "智能客服",
  "navigationBarBackgroundColor": "#ffffff",
  "navigationBarTextStyle": "black"
}
```

### 4. 配置小程序业务域名

在小程序管理后台配置业务域名：
1. 登录微信公众平台
2. 进入"开发" -> "开发管理" -> "开发设置"
3. 在"业务域名"中添加你的域名
4. 下载校验文件并放到服务器根目录

## 配置说明

### 后端配置 (backend/config/config.yaml)

```yaml
server:
  port: 8080              # 服务端口
  mode: release           # 运行模式: debug/release

database:
  host: localhost         # 数据库地址
  port: 3306             # 数据库端口
  user: root             # 数据库用户名
  password: your_password # 数据库密码
  dbname: msl_customer_service

redis:
  host: localhost         # Redis地址
  port: 6379             # Redis端口
  password: ""           # Redis密码

jwt:
  secret: your-secret-key # JWT密钥（生产环境必须修改）
  expire: 7200           # 过期时间（秒）

ai:
  provider: openai        # AI提供商
  api_key: your-api-key  # OpenAI API Key
  model: gpt-3.5-turbo   # 使用的模型
  base_url: https://api.openai.com/v1
```

### 前端配置

在 `frontend/src/utils/websocket.js` 中可以调整WebSocket连接参数：
- 重连次数
- 重连间隔
- 心跳间隔

## API文档

### 认证相关

#### POST /api/auth/verify
验证小程序token

请求：
```json
{
  "token": "小程序token",
  "userMobile": "手机号",
  "userName": "用户名"
}
```

响应：
```json
{
  "code": 0,
  "msg": "验证成功",
  "data": {
    "userId": 1,
    "userMobile": "13800138000",
    "userName": "张三"
  }
}
```

### WebSocket连接

#### GET /api/ws?token=xxx
建立WebSocket连接

消息格式：
```json
{
  "type": "text",      // 消息类型: text/image
  "content": "消息内容"
}
```

### FAQ相关

#### GET /api/faq/list
获取FAQ列表

#### GET /api/faq/categories
获取FAQ分类

### 反馈相关

#### POST /api/feedback
提交反馈

## 生产环境部署

### 1. 服务器要求

- CPU: 2核+
- 内存: 4GB+
- 硬盘: 20GB+
- 系统: Ubuntu 20.04+ / CentOS 7+

### 2. 安全配置

#### 修改默认密码
```bash
# 修改MySQL密码
# 修改Redis密码（如果需要）
# 修改JWT密钥
```

#### 配置防火墙
```bash
# 开放必要端口
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

#### 配置HTTPS
```bash
# 使用Let's Encrypt获取免费SSL证书
apt install certbot
certbot certonly --standalone -d your-domain.com
```

修改 `frontend/nginx.conf` 添加SSL配置：
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # ... 其他配置
}
```

### 3. 性能优化

#### 数据库优化
```sql
-- 添加索引
CREATE INDEX idx_user_token ON users(token);
CREATE INDEX idx_conversation_user ON conversations(user_id);
CREATE INDEX idx_message_conversation ON messages(conversation_id);
```

#### Redis缓存
- 缓存热门FAQ
- 缓存用户会话信息
- 缓存AI回复

### 4. 监控和日志

#### 日志收集
```bash
# 查看后端日志
docker-compose logs -f backend

# 查看前端日志
docker-compose logs -f frontend
```

#### 健康检查
```bash
# 检查服务状态
curl http://localhost:8080/health
```

## 常见问题

### 1. WebSocket连接失败
- 检查防火墙配置
- 检查Nginx代理配置
- 确认token有效性

### 2. AI回复慢
- 检查OpenAI API连接
- 考虑使用国内代理
- 优化FAQ匹配逻辑

### 3. 数据库连接失败
- 检查数据库配置
- 确认数据库服务运行
- 检查网络连接

## 维护和更新

### 备份数据
```bash
# 备份MySQL
docker exec msl-cs-mysql mysqldump -u root -p msl_customer_service > backup.sql

# 备份上传文件
tar -czf uploads_backup.tar.gz backend/uploads/
```

### 更新服务
```bash
# 拉取最新代码
git pull

# 重新构建
docker-compose build

# 重启服务
docker-compose up -d
```

## 许可证

本项目仅供马上来场站服务系统内部使用。

## 联系方式

如有问题，请联系技术支持团队。

