package models

import (
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	UserNo    string         `gorm:"uniqueIndex;size:50" json:"userNo"`
	UserName  string         `gorm:"size:100" json:"userName"`
	Mobile    string         `gorm:"size:20" json:"mobile"`
	Avatar    string         `gorm:"size:255" json:"avatar"`
	IsOnline  bool           `gorm:"default:false" json:"isOnline"`
	LastSeen  *time.Time     `json:"lastSeen"`
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

