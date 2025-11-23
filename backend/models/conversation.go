package models

import (
	"time"

	"gorm.io/gorm"
)

type Conversation struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	UserID    uint           `gorm:"index" json:"userId"`
	User      User           `gorm:"foreignKey:UserID" json:"user"`
	Status    string         `gorm:"size:20;default:'active'" json:"status"` // active, closed
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

