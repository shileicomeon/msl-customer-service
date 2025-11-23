package main

import (
	"fmt"
	"log"
	"msl-customer-service/config"
	"msl-customer-service/internal/database"
	"msl-customer-service/internal/router"
	"msl-customer-service/internal/service"

	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg, err := config.LoadConfig("./config/config.yaml")
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 初始化数据库
	if err := database.InitDB(cfg); err != nil {
		log.Fatalf("初始化数据库失败: %v", err)
	}

	// 初始化Redis（可选，失败时只警告）
	if err := database.InitRedis(cfg); err != nil {
		log.Printf("警告: Redis初始化失败（将不使用Redis缓存）: %v", err)
	}

	// 初始化WebSocket管理器
	service.InitHub()
	go service.GetHub().Run()

	// 设置Gin模式
	gin.SetMode(cfg.Server.Mode)

	// 初始化路由
	r := router.SetupRouter(cfg)

	// 启动服务器
	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	log.Printf("服务器启动在 %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("服务器启动失败: %v", err)
	}
}
