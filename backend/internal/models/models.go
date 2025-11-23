package models

import (
	"time"

	"gorm.io/gorm"
)

// User 用户表
type User struct {
	ID         uint           `gorm:"primarykey" json:"id"`
	UserMobile string         `gorm:"size:20;uniqueIndex" json:"userMobile"`
	UserName   string         `gorm:"size:100" json:"userName"`
	CompanyNo  string         `gorm:"size:50" json:"companyNo"`
	Token      string         `gorm:"size:500" json:"-"`
	CreatedAt  time.Time      `json:"createdAt"`
	UpdatedAt  time.Time      `json:"updatedAt"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`
}

// Conversation 会话表
type Conversation struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	UserID    uint           `gorm:"index" json:"userId"`
	SessionID string         `gorm:"size:100;uniqueIndex" json:"sessionId"`
	Status    int            `gorm:"default:1" json:"status"` // 1:进行中 2:已结束
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	User      User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// Message 消息表
type Message struct {
	ID             uint           `gorm:"primarykey" json:"id"`
	ConversationID uint           `gorm:"index" json:"conversationId"`
	SenderType     string         `gorm:"size:20" json:"senderType"` // user, ai, system
	Content        string         `gorm:"type:text" json:"content"`
	MessageType    string         `gorm:"size:20" json:"messageType"` // text, image, file
	FileURL        string         `gorm:"size:500" json:"fileUrl,omitempty"`
	CreatedAt      time.Time      `json:"createdAt"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
	Conversation   Conversation   `gorm:"foreignKey:ConversationID" json:"-"`
}

// FAQ 常见问题表
type FAQ struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	Question  string         `gorm:"type:text" json:"question"`
	Answer    string         `gorm:"type:text" json:"answer"`
	Category  string         `gorm:"size:50" json:"category"`
	Keywords  string         `gorm:"type:text" json:"keywords"` // 关键词，用逗号分隔
	ViewCount int            `gorm:"default:0" json:"viewCount"`
	Status    int            `gorm:"default:1" json:"status"` // 1:启用 0:禁用
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Feedback 用户反馈表
type Feedback struct {
	ID             uint           `gorm:"primarykey" json:"id"`
	ConversationID uint           `gorm:"index" json:"conversationId"`
	UserID         uint           `gorm:"index" json:"userId"`
	Rating         int            `gorm:"default:0" json:"rating"` // 1-5星
	Content        string         `gorm:"type:text" json:"content"`
	CreatedAt      time.Time      `json:"createdAt"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
}

