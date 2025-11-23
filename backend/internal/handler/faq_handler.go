package handler

import (
	"msl-customer-service/config"
	"msl-customer-service/internal/database"
	"msl-customer-service/internal/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

type FAQHandler struct {
	cfg *config.Config
}

func NewFAQHandler(cfg *config.Config) *FAQHandler {
	return &FAQHandler{cfg: cfg}
}

// GetFAQList 获取FAQ列表
func (h *FAQHandler) GetFAQList(c *gin.Context) {
	category := c.Query("category")

	var faqs []models.FAQ
	query := database.GetDB().Where("status = ?", 1)

	if category != "" {
		query = query.Where("category = ?", category)
	}

	query.Order("view_count DESC").Find(&faqs)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": faqs,
	})
}

// GetFAQCategories 获取FAQ分类
func (h *FAQHandler) GetFAQCategories(c *gin.Context) {
	var categories []string
	database.GetDB().Model(&models.FAQ{}).
		Where("status = ?", 1).
		Distinct("category").
		Pluck("category", &categories)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": categories,
	})
}

// SubmitFeedback 提交反馈
func (h *FAQHandler) SubmitFeedback(c *gin.Context) {
	var req struct {
		ConversationID uint   `json:"conversationId"`
		Rating         int    `json:"rating" binding:"required,min=1,max=5"`
		Content        string `json:"content"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": -1,
			"msg":  "参数错误",
		})
		return
	}

	userID := c.GetUint("userId")

	feedback := models.Feedback{
		ConversationID: req.ConversationID,
		UserID:         userID,
		Rating:         req.Rating,
		Content:        req.Content,
	}

	if err := database.GetDB().Create(&feedback).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": -1,
			"msg":  "提交反馈失败",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "感谢您的反馈！",
	})
}

