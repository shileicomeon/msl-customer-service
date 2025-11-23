package middleware

import (
	"fmt"
	"msl-customer-service/config"
	"msl-customer-service/internal/database"
	"msl-customer-service/internal/models"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID     uint   `json:"userId"`
	UserMobile string `json:"userMobile"`
	jwt.RegisteredClaims
}

// AuthMiddleware JWT认证中间件
func AuthMiddleware(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 从请求头获取token
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			// 尝试从query参数获取（用于WebSocket）
			authHeader = c.Query("token")
		}

		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code": -100,
				"msg":  "未提供认证令牌",
			})
			c.Abort()
			return
		}

		// 移除Bearer前缀
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")

		// 验证小程序传来的token
		var user models.User
		if err := database.GetDB().Where("token = ?", tokenString).First(&user).Error; err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"code": -100,
				"msg":  "无效的认证令牌",
			})
			c.Abort()
			return
		}

		// 将用户信息存入上下文
		c.Set("userId", user.ID)
		c.Set("userMobile", user.UserMobile)
		c.Set("userName", user.UserName)
		c.Next()
	}
}

// GenerateToken 生成JWT token
func GenerateToken(cfg *config.Config, userID uint, userMobile string) (string, error) {
	claims := Claims{
		UserID:     userID,
		UserMobile: userMobile,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Duration(cfg.JWT.Expire) * time.Second)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(cfg.JWT.Secret))
}

// ParseToken 解析JWT token
func ParseToken(cfg *config.Config, tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(cfg.JWT.Secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}

