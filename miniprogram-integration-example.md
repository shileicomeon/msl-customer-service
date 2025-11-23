# 小程序集成示例

## 1. 在个人中心添加客服入口

### 修改 `miniprogram/pages/mine/mine.wxml`

在适当位置添加客服菜单项：

```xml
<!-- 在联系我们或其他菜单项附近添加 -->
<view class="menu-item" bindtap="onCustomerService">
  <view class="menu-item-left">
    <van-icon name="service-o" size="20px" color="#FA8F46" />
    <text class="menu-item-text">智能客服</text>
  </view>
  <van-icon name="arrow" color="#C0C4CC" />
</view>
```

### 修改 `miniprogram/pages/mine/mine.ts`

添加客服跳转方法：

```typescript
// 在 Page 对象中添加方法
onCustomerService() {
  // 检查登录状态
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
    url: `/pages/customer-service/index?token=${token}&userMobile=${encodeURIComponent(userMobile)}&userName=${encodeURIComponent(userName)}`,
  });
},
```

## 2. 创建客服页面

### 创建目录结构

```
miniprogram/pages/customer-service/
├── index.wxml
├── index.ts
├── index.json
└── index.wxss
```

### index.wxml

```xml
<web-view src="{{webviewUrl}}" bindmessage="onMessage"></web-view>
```

### index.ts

```typescript
Page({
  data: {
    webviewUrl: "",
  },

  onLoad(options: any) {
    const { token, userMobile, userName } = options;

    // 生产环境域名（需要替换为实际域名）
    const baseUrl = "https://your-domain.com";

    // 开发环境可以使用测试域名
    // const baseUrl = 'http://your-test-domain.com';

    const url = `${baseUrl}?token=${token}&userMobile=${encodeURIComponent(
      userMobile
    )}&userName=${encodeURIComponent(userName)}`;

    console.log("客服页面URL:", url);

    this.setData({
      webviewUrl: url,
    });
  },

  onMessage(e: any) {
    // 接收web-view消息
    console.log("收到web-view消息:", e.detail.data);
  },

  onShareAppMessage() {
    return {
      title: "马上来智能客服",
      path: "/pages/customer-service/index",
    };
  },
});
```

### index.json

```json
{
  "navigationBarTitleText": "智能客服",
  "navigationBarBackgroundColor": "#ffffff",
  "navigationBarTextStyle": "black",
  "enablePullDownRefresh": false
}
```

### index.wxss

```css
page {
  height: 100%;
}

web-view {
  width: 100%;
  height: 100%;
}
```

## 3. 配置 app.json

在 `miniprogram/app.json` 的 `pages` 数组中添加客服页面路径：

```json
{
  "pages": [
    "pages/wait/wait",
    "pages/order/index",
    "pages/mine/mine",
    "pages/customer-service/index" // 添加这一行
  ]
}
```

## 4. 配置业务域名

### 4.1 登录微信公众平台

访问：https://mp.weixin.qq.com

### 4.2 配置业务域名

1. 进入"开发" -> "开发管理" -> "开发设置"
2. 找到"业务域名"配置项
3. 点击"开始配置"
4. 下载校验文件（例如：WxVerifyFile.txt）
5. 将校验文件上传到服务器根目录
6. 在配置框中输入域名（不带协议）：`your-domain.com`
7. 点击"保存"

### 4.3 校验文件放置

将下载的校验文件放到服务器的以下位置：

```
/usr/share/nginx/html/WxVerifyFile.txt
```

或者修改 `frontend/nginx.conf` 添加：

```nginx
location /WxVerifyFile.txt {
    root /usr/share/nginx/html;
}
```

## 5. 可选：添加快捷入口

### 5.1 在运单详情页添加客服按钮

在 `miniprogram/pages/order/details/index.wxml` 中：

```xml
<view class="help-button" bindtap="onContactService">
  <van-icon name="service-o" />
  <text>需要帮助？</text>
</view>
```

在 `miniprogram/pages/order/details/index.ts` 中：

```typescript
onContactService() {
  const token = wx.getStorageSync("token");
  const userInfo = wx.getStorageSync("userInfo");

  wx.navigateTo({
    url: `/pages/customer-service/index?token=${token}&userMobile=${userInfo.userMobile}&userName=${userInfo.userName}`,
  });
},
```

### 5.2 在排队叫号页添加客服按钮

在 `miniprogram/pages/wait/wait.wxml` 的顶部添加：

```xml
<view class="header-right">
  <van-icon name="service-o" size="20px" bindtap="onContactService" />
</view>
```

## 6. 测试流程

### 6.1 开发环境测试

1. 启动后端服务
2. 启动前端服务
3. 在微信开发者工具中打开小程序
4. 点击"个人中心" -> "智能客服"
5. 测试聊天功能

### 6.2 真机测试

1. 确保服务器已部署并可访问
2. 配置好业务域名
3. 在微信开发者工具中点击"预览"
4. 用手机扫码测试

## 7. 常见问题

### Q1: web-view 白屏

**原因：**

- 业务域名未配置
- 校验文件未上传
- HTTPS 证书问题

**解决：**

1. 检查业务域名配置
2. 确认校验文件可访问
3. 使用 HTTPS 协议

### Q2: 无法连接 WebSocket

**原因：**

- 服务器防火墙阻止
- Nginx 配置问题
- token 无效

**解决：**

1. 检查服务器端口开放
2. 检查 Nginx WebSocket 代理配置
3. 确认 token 正确传递

### Q3: 页面显示但无法交互

**原因：**

- token 验证失败
- 网络请求被拦截

**解决：**

1. 检查 token 是否正确
2. 在后端日志中查看错误信息
3. 检查网络请求状态

## 8. 性能优化建议

### 8.1 预加载

在小程序启动时预加载客服页面：

```typescript
// app.ts
onLaunch() {
  // 预加载客服页面
  wx.preloadWebview({
    url: 'https://your-domain.com'
  });
}
```

### 8.2 缓存优化

在前端添加资源缓存：

```javascript
// 在 vue.config.js 中配置
pwa: {
  workboxOptions: {
    cacheId: 'msl-customer-service',
    runtimeCaching: [
      {
        urlPattern: /^https:\/\/your-domain\.com/,
        handler: 'NetworkFirst',
        options: {
          cacheName: 'api-cache',
          expiration: {
            maxEntries: 50,
            maxAgeSeconds: 300
          }
        }
      }
    ]
  }
}
```

## 9. 监控和统计

### 9.1 添加访问统计

在客服页面添加统计代码：

```typescript
// 在 ChatView.vue 的 onMounted 中
onMounted(() => {
  // 记录访问
  console.log("客服页面访问", {
    userMobile: userStore.userInfo?.userMobile,
    timestamp: new Date().toISOString(),
  });
});
```

### 9.2 后端日志

在后端添加访问日志：

```go
// 在 WebSocket 连接时记录
log.Printf("客服连接: UserID=%d, UserMobile=%s, IP=%s",
  userID, userMobile, c.ClientIP())
```

## 10. 安全建议

1. **Token 加密传输**

   - 使用 HTTPS 协议
   - Token 有效期设置合理

2. **防止重放攻击**

   - Token 添加时间戳
   - 服务端验证时间有效性

3. **内容安全**

   - 过滤敏感信息
   - XSS 防护
   - SQL 注入防护

4. **访问限制**
   - 添加访问频率限制
   - IP 白名单（如需要）
   - 异常访问检测
