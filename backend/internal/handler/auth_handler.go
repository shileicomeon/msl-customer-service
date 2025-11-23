package handler

import (
	"msl-customer-service/config"
	"msl-customer-service/internal/database"
	"msl-customer-service/internal/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	cfg *config.Config
}

func NewAuthHandler(cfg *config.Config) *AuthHandler {
	return &AuthHandler{cfg: cfg}
}

// VerifyToken 验证小程序传来的token
func (h *AuthHandler) VerifyToken(c *gin.Context) {
	var req struct {
		Token      string `json:"token" binding:"required"`
		UserMobile string `json:"userMobile"`
		UserName   string `json:"userName"`
		CompanyNo  string `json:"companyNo"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": -1,
			"msg":  "参数错误",
		})
		return
	}

	// 查找或创建用户
	var user models.User
	result := database.GetDB().Where("token = ?", req.Token).First(&user)

	if result.Error != nil {
		// 用户不存在，创建新用户
		user = models.User{
			UserMobile: req.UserMobile,
			UserName:   req.UserName,
			CompanyNo:  req.CompanyNo,
			Token:      req.Token,
		}
		if err := database.GetDB().Create(&user).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{
				"code": -1,
				"msg":  "创建用户失败",
			})
			return
		}
	} else {
		// 更新用户信息
		user.UserMobile = req.UserMobile
		user.UserName = req.UserName
		user.CompanyNo = req.CompanyNo
		database.GetDB().Save(&user)
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "验证成功",
		"data": gin.H{
			"userId":     user.ID,
			"userMobile": user.UserMobile,
			"userName":   user.UserName,
		},
	})
}

// GetUserInfo 获取用户信息
func (h *AuthHandler) GetUserInfo(c *gin.Context) {
	userID := c.GetUint("userId")

	var user models.User
	if err := database.GetDB().First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"code": -1,
			"msg":  "用户不存在",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"data": user,
	})
}

