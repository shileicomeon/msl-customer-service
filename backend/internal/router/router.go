package router

import (
	"msl-customer-service/config"
	"msl-customer-service/internal/handler"
	"msl-customer-service/internal/middleware"

	"github.com/gin-gonic/gin"
)

func SetupRouter(cfg *config.Config) *gin.Engine {
	r := gin.Default()

	// 跨域中间件
	r.Use(middleware.CORSMiddleware())

	// 初始化处理器
	authHandler := handler.NewAuthHandler(cfg)
	chatHandler := handler.NewChatHandler(cfg)
	uploadHandler := handler.NewUploadHandler(cfg)
	faqHandler := handler.NewFAQHandler(cfg)

	// 公开路由
	public := r.Group("/api")
	{
		// 认证相关
		public.POST("/auth/verify", authHandler.VerifyToken)

		// FAQ相关（不需要认证）
		public.GET("/faq/list", faqHandler.GetFAQList)
		public.GET("/faq/categories", faqHandler.GetFAQCategories)
	}

	// 需要认证的路由
	protected := r.Group("/api")
	protected.Use(middleware.AuthMiddleware(cfg))
	{
		// 用户信息
		protected.GET("/user/info", authHandler.GetUserInfo)

		// WebSocket连接
		protected.GET("/ws", chatHandler.HandleWebSocket)

		// 会话管理
		protected.GET("/conversations", chatHandler.GetConversations)
		protected.GET("/conversations/:sessionId/messages", chatHandler.GetMessages)
		protected.POST("/conversations/:sessionId/end", chatHandler.EndConversation)

		// 文件上传
		protected.POST("/upload", uploadHandler.UploadFile)

		// 反馈
		protected.POST("/feedback", faqHandler.SubmitFeedback)
	}

	// 静态文件服务
	r.GET("/uploads/:filename", uploadHandler.ServeFile)

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "ok",
		})
	})

	return r
}

