package handler

import (
	"fmt"
	"msl-customer-service/config"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type UploadHandler struct {
	cfg *config.Config
}

func NewUploadHandler(cfg *config.Config) *UploadHandler {
	return &UploadHandler{cfg: cfg}
}

// UploadFile 上传文件
func (h *UploadHandler) UploadFile(c *gin.Context) {
	file, err := c.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": -1,
			"msg":  "文件上传失败",
		})
		return
	}

	// 检查文件大小
	if file.Size > h.cfg.Upload.MaxSize {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": -1,
			"msg":  fmt.Sprintf("文件大小超过限制（最大%dMB）", h.cfg.Upload.MaxSize/1024/1024),
		})
		return
	}

	// 检查文件类型
	contentType := file.Header.Get("Content-Type")
	allowed := false
	for _, t := range h.cfg.Upload.AllowedTypes {
		if t == contentType {
			allowed = true
			break
		}
	}
	if !allowed {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": -1,
			"msg":  "不支持的文件类型",
		})
		return
	}

	// 创建上传目录
	uploadPath := h.cfg.Upload.SavePath
	if err := os.MkdirAll(uploadPath, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": -1,
			"msg":  "创建上传目录失败",
		})
		return
	}

	// 生成唯一文件名
	ext := filepath.Ext(file.Filename)
	filename := fmt.Sprintf("%s_%s%s", time.Now().Format("20060102"), uuid.New().String(), ext)
	filePath := filepath.Join(uploadPath, filename)

	// 保存文件
	if err := c.SaveUploadedFile(file, filePath); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code": -1,
			"msg":  "保存文件失败",
		})
		return
	}

	// 返回文件URL
	fileURL := fmt.Sprintf("/uploads/%s", filename)

	c.JSON(http.StatusOK, gin.H{
		"code": 0,
		"msg":  "上传成功",
		"data": gin.H{
			"url":      fileURL,
			"filename": file.Filename,
			"size":     file.Size,
		},
	})
}

// ServeFile 提供文件访问
func (h *UploadHandler) ServeFile(c *gin.Context) {
	filename := c.Param("filename")

	// 防止路径遍历攻击
	if strings.Contains(filename, "..") {
		c.JSON(http.StatusBadRequest, gin.H{
			"code": -1,
			"msg":  "非法的文件名",
		})
		return
	}

	filePath := filepath.Join(h.cfg.Upload.SavePath, filename)

	// 检查文件是否存在
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{
			"code": -1,
			"msg":  "文件不存在",
		})
		return
	}

	c.File(filePath)
}

