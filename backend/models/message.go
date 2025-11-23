package models

import (
	"time"

	"gorm.io/gorm"
)

type Message struct {
	ID             uint           `gorm:"primarykey" json:"id"`
	ConversationID uint           `gorm:"index" json:"conversationId"`
	Conversation   Conversation   `gorm:"foreignKey:ConversationID" json:"-"`
	SenderID       uint           `gorm:"index" json:"senderId"`
	Sender         User           `gorm:"foreignKey:SenderID" json:"sender"`
	Content        string         `gorm:"type:text" json:"content"`
	MessageType    string         `gorm:"size:20;default:'text'" json:"messageType"` // text, image, file, system
	FileURL        string         `gorm:"size:500" json:"fileUrl,omitempty"`
	IsRead         bool           `gorm:"default:false" json:"isRead"`
	IsAI           bool           `gorm:"default:false" json:"isAi"` // 是否为AI回复
	CreatedAt      time.Time      `json:"createdAt"`
	UpdatedAt      time.Time      `json:"updatedAt"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
}

