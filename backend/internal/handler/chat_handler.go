package handler

import (
	"encoding/json"
	"log"
	"msl-customer-service/config"
	"msl-customer-service/internal/database"
	"msl-customer-service/internal/models"
	"msl-customer-service/internal/service"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // 允许所有来源
	},
}

type ChatHandler struct {
	cfg       *config.Config
	aiService *service.AIService
}

func NewChatHandler(cfg *config.Config) *ChatHandler {
	return &ChatHandler{
		cfg:       cfg,
		aiService: service.NewAIService(cfg),
	}
}

// HandleWebSocket 处理WebSocket连接
func (h *ChatHandler) HandleWebSocket(c *gin.Context) {
	userID := c.GetUint("userId")
	if userID == 0 {
		c.JSON(http.StatusUnauthorized, gin.H{
			"code": -100,
			"msg":  "未授权",
		})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket升级失败: %v", err)
		return
	}

	// 创建或获取会话
	sessionID := c.Query("sessionId")
	if sessionID == "" {
		sessionID = uuid.New().String()
	}

	var conversation models.Conversation
	result := database.GetDB().Where("session_id = ? AND user_id = ?", sessionID, userID).First(&conversation)
	if result.Error != nil {
		// 创建新会话
		conversation = models.Conversation{
			UserID:    userID,
			SessionID: sessionID,
			Status:    1,
		}
		database.GetDB().Create(&conversation)
	}

	// 创建客户端
	client := &service.Client{
		Hub:       service.GetHub(),
		Conn:      conn,
		Send:      make(chan []byte, 256),
		UserID:    userID,
		SessionID: sessionID,
	}

	client.Hub.Register <- client

	// 发送欢迎消息
	welcomeMsg := map[string]interface{}{
		"type":      "system",
		"content":   "欢迎使用马上来场站服务系统智能客服！有什么可以帮您的吗？",
		"timestamp": time.Now().Unix(),
	}
	welcomeData, _ := json.Marshal(welcomeMsg)
	client.Send <- welcomeData

	// 启动读写协程
	go client.WritePump()
	go h.handleMessages(client, conversation.ID)
	client.ReadPump()
}

// handleMessages 处理接收到的消息
func (h *ChatHandler) handleMessages(client *service.Client, conversationID uint) {
	for {
		_, message, err := client.Conn.ReadMessage()
		if err != nil {
			break
		}

		var msg map[string]interface{}
		if err := json.Unmarshal(message, &msg); err != nil {
			continue
		}

		content, ok := msg["content"].(string)
		if !ok || content == "" {
			continue
		}

		messageType := "text"
		if t, ok := msg["type"].(string); ok {
			messageType = t
		}

		// 保存用户消息
		userMsg := models.Message{
			ConversationID: conversationID,
			SenderType:     "user",
			Content:        content,
			MessageType:    messageType,
		}
		database.GetDB().Create(&userMsg)

		// 获取AI回复
		aiResponse, err := h.aiService.GetAIResponse(content, conversationID)
		if err != nil {
			log.Printf("AI服务错误: %v", err)
			aiResponse = "抱歉，服务暂时不可用，请稍后再试。"
		}

		// 保存AI回复
		aiMsg := models.Message{
			ConversationID: conversationID,
			SenderType:     "ai",
			Content:        aiResponse,
			MessageType:    "text",
		}
		database.GetDB().Create(&aiMsg)

		// 发送AI回复给用户
		response := map[string]interface{}{
			"type":      "ai",
			"content":   aiResponse,
			"timestamp": time.Now().Unix(),
			"messageId": aiMsg.ID,
		}
		responseData, _ := json.Marshal(response)
		client.Send <- responseData
	}
}

// GetConversations 获取用户的会话列表
func (h *ChatHandler) GetConversations(c *gin.Context) {
	userID := c.GetUint("userId")

	var conversations []models.Conversation
	database.GetDB().Where("user_id = ?", userID).
		Order("updated_at DESC").
		Find(&conversations)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": conversations,
	})
}

// GetMessages 获取会话的消息列表
func (h *ChatHandler) GetMessages(c *gin.Context) {
	sessionID := c.Param("sessionId")
	userID := c.GetUint("userId")

	var conversation models.Conversation
	if err := database.GetDB().Where("session_id = ? AND user_id = ?", sessionID, userID).First(&conversation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code": -1,
			"msg":  "会话不存在",
		})
		return
	}

	var messages []models.Message
	database.GetDB().Where("conversation_id = ?", conversation.ID).
		Order("created_at ASC").
		Find(&messages)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": messages,
	})
}

// EndConversation 结束会话
func (h *ChatHandler) EndConversation(c *gin.Context) {
	sessionID := c.Param("sessionId")
	userID := c.GetUint("userId")

	var conversation models.Conversation
	if err := database.GetDB().Where("session_id = ? AND user_id = ?", sessionID, userID).First(&conversation).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code": -1,
			"msg":  "会话不存在",
		})
		return
	}

	conversation.Status = 2
	database.GetDB().Save(&conversation)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "会话已结束",
	})
}

