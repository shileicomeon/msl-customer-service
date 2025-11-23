# 马上来智能客服系统 - 项目总览

## 项目信息

- **项目名称**: 马上来场站服务系统 - 智能客服
- **项目位置**: `/Users/shialei/vueProjectDemo/msl-customer-service`
- **开发时间**: 2024
- **技术栈**: Go + Vue3 + WebSocket + MySQL + Redis

## 系统架构

```
┌─────────────┐
│ 微信小程序   │
│  (客户端)    │
└──────┬──────┘
       │ token传递
       ↓
┌─────────────┐
│  Web-View   │
│  (Vue前端)  │
└──────┬──────┘
       │ WebSocket + HTTP
       ↓
┌─────────────┐      ┌─────────┐
│  Go后端服务  │─────→│  MySQL  │
│  (API+WS)   │      └─────────┘
└──────┬──────┘
       │              ┌─────────┐
       └─────────────→│  Redis  │
                      └─────────┘
       │              ┌─────────┐
       └─────────────→│ OpenAI  │
                      └─────────┘
```

## 核心功能模块

### 1. 用户认证模块

- **文件**: `backend/internal/middleware/auth.go`
- **功能**:
  - 验证小程序 token
  - 用户信息管理
  - JWT 生成和验证

### 2. WebSocket 通信模块

- **文件**: `backend/internal/service/websocket.go`
- **功能**:
  - 实时消息推送
  - 连接管理
  - 心跳检测
  - 自动重连

### 3. AI 智能客服模块

- **文件**: `backend/internal/service/ai_service.go`
- **功能**:
  - FAQ 智能匹配
  - OpenAI 集成
  - 上下文理解
  - 关键词搜索

### 4. 消息存储模块

- **文件**: `backend/internal/models/models.go`
- **功能**:
  - 会话管理
  - 消息记录
  - 用户反馈
  - FAQ 管理

### 5. 文件上传模块

- **文件**: `backend/internal/handler/upload_handler.go`
- **功能**:
  - 图片上传
  - 文件验证
  - 大小限制
  - 类型检查

### 6. 前端聊天界面

- **文件**: `frontend/src/views/ChatView.vue`
- **功能**:
  - 响应式设计
  - 消息展示
  - 输入框
  - FAQ 弹窗
  - 反馈表单

## 数据库设计

### 表结构

#### users (用户表)

```sql
- id: 主键
- user_mobile: 手机号
- user_name: 用户名
- company_no: 公司编号
- token: 认证令牌
- created_at: 创建时间
- updated_at: 更新时间
```

#### conversations (会话表)

```sql
- id: 主键
- user_id: 用户ID
- session_id: 会话ID
- status: 状态(1:进行中 2:已结束)
- created_at: 创建时间
- updated_at: 更新时间
```

#### messages (消息表)

```sql
- id: 主键
- conversation_id: 会话ID
- sender_type: 发送者类型(user/ai/system)
- content: 消息内容
- message_type: 消息类型(text/image/file)
- file_url: 文件URL
- created_at: 创建时间
```

#### faqs (常见问题表)

```sql
- id: 主键
- question: 问题
- answer: 答案
- category: 分类
- keywords: 关键词
- view_count: 查看次数
- status: 状态(1:启用 0:禁用)
- created_at: 创建时间
- updated_at: 更新时间
```

#### feedbacks (反馈表)

```sql
- id: 主键
- conversation_id: 会话ID
- user_id: 用户ID
- rating: 评分(1-5)
- content: 反馈内容
- created_at: 创建时间
```

## API 接口列表

### 认证接口

- `POST /api/auth/verify` - 验证 token
- `GET /api/user/info` - 获取用户信息

### WebSocket 接口

- `GET /api/ws` - WebSocket 连接

### 会话接口

- `GET /api/conversations` - 获取会话列表
- `GET /api/conversations/:sessionId/messages` - 获取消息列表
- `POST /api/conversations/:sessionId/end` - 结束会话

### FAQ 接口

- `GET /api/faq/list` - 获取 FAQ 列表
- `GET /api/faq/categories` - 获取 FAQ 分类

### 上传接口

- `POST /api/upload` - 上传文件
- `GET /uploads/:filename` - 访问文件

### 反馈接口

- `POST /api/feedback` - 提交反馈

### 健康检查

- `GET /health` - 健康检查

## 部署流程

### 开发环境

```bash
# 后端
cd backend
go run main.go

# 前端
cd frontend
npm run serve
```

### 生产环境

```bash
# 使用Docker Compose
docker-compose up -d

# 或使用启动脚本
./start.sh
```

## 配置清单

### 必须配置项

- [ ] 数据库连接信息
- [ ] Redis 连接信息
- [ ] JWT 密钥
- [ ] OpenAI API Key
- [ ] 服务器域名
- [ ] 小程序业务域名

### 可选配置项

- [ ] 文件上传大小限制
- [ ] WebSocket 重连参数
- [ ] AI 模型参数
- [ ] 日志级别

## 小程序集成步骤

1. **添加客服入口**

   - 在个人中心添加"智能客服"菜单
   - 实现跳转逻辑

2. **创建客服页面**

   - 创建 web-view 页面
   - 配置页面参数

3. **配置业务域名**

   - 登录微信公众平台
   - 上传校验文件
   - 添加域名

4. **测试验证**
   - 开发环境测试
   - 真机测试
   - 功能验证

详细步骤请参考: `miniprogram-integration-example.md`

## 性能指标

### 目标指标

- WebSocket 连接成功率: >99%
- 消息响应时间: <500ms
- AI 回复时间: <3s
- 页面加载时间: <2s
- 并发用户数: 1000+

### 监控指标

- 在线用户数
- 消息发送量
- AI 调用次数
- 错误率
- 响应时间

## 安全措施

### 已实现

- [x] Token 认证
- [x] CORS 跨域保护
- [x] 文件类型验证
- [x] 文件大小限制
- [x] SQL 注入防护(GORM)
- [x] XSS 防护

### 建议增强

- [ ] 访问频率限制
- [ ] IP 白名单
- [ ] 内容审核
- [ ] 敏感词过滤
- [ ] 日志审计

## 扩展功能建议

### 短期(1-2 周)

1. 添加消息已读/未读状态
2. 支持语音消息
3. 添加表情包
4. 优化移动端体验

### 中期(1-2 月)

1. 添加人工客服转接
2. 客服工作台
3. 数据统计分析
4. 多语言支持

### 长期(3-6 月)

1. 知识库管理系统
2. AI 训练和优化
3. 智能推荐
4. 客户画像分析

## 维护计划

### 日常维护

- 每日检查服务状态
- 监控错误日志
- 备份数据库

### 定期维护

- 每周更新 FAQ
- 每月性能优化
- 每季度安全审计

### 应急预案

- 服务宕机处理流程
- 数据恢复流程
- 安全事件响应流程

## 文档索引

1. **README.md** - 项目说明和快速开始
2. **PROJECT_OVERVIEW.md** - 本文件，项目总览
3. **miniprogram-integration-example.md** - 小程序集成指南
4. **backend/config/config.yaml** - 后端配置文件
5. **docker-compose.yml** - Docker 部署配置
6. **init.sql** - 数据库初始化脚本

## 技术支持

### 常见问题

请查看 README.md 中的"常见问题"章节

### 问题反馈

- 技术问题: 查看日志文件
- 功能建议: 提交到项目管理系统
- 紧急问题: 联系技术负责人

## 更新日志

### v1.0.0 (2024-11-23)

- ✅ 完成基础架构搭建
- ✅ 实现用户认证
- ✅ 实现 WebSocket 通信
- ✅ 集成 AI 智能客服
- ✅ 实现消息存储
- ✅ 实现文件上传
- ✅ 完成前端界面
- ✅ 配置 Docker 部署
- ✅ 编写部署文档

### 计划中

- 🔄 添加人工客服
- 🔄 优化 AI 回复质量
- 🔄 增加数据统计
- 🔄 性能优化

## 总结

本项目是一个完整的智能客服解决方案，具有以下特点：

1. **技术先进**: 采用 Go + Vue3 + WebSocket 现代技术栈
2. **功能完善**: 包含认证、聊天、AI、文件上传等完整功能
3. **易于部署**: 提供 Docker 一键部署方案
4. **文档齐全**: 包含详细的开发和部署文档
5. **可扩展性**: 模块化设计，易于扩展新功能
6. **兼容性好**: 支持 PC 和移动端，响应式设计

项目已经可以直接部署使用，后续可根据实际需求进行功能扩展和优化。
