package models

import (
	"time"

	"gorm.io/gorm"
)

type File struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	UserID    uint           `gorm:"index" json:"userId"`
	FileName  string         `gorm:"size:255" json:"fileName"`
	FileSize  int64          `json:"fileSize"`
	FileType  string         `gorm:"size:50" json:"fileType"`
	FilePath  string         `gorm:"size:500" json:"filePath"`
	FileURL   string         `gorm:"size:500" json:"fileUrl"`
	CreatedAt time.Time      `json:"createdAt"`
	UpdatedAt time.Time      `json:"updatedAt"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

