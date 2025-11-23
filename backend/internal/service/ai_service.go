package service

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"msl-customer-service/config"
	"msl-customer-service/internal/database"
	"msl-customer-service/internal/models"
	"net/http"
	"strings"
)

type AIService struct {
	cfg *config.Config
}

func NewAIService(cfg *config.Config) *AIService {
	return &AIService{cfg: cfg}
}

// OpenAI请求结构
type OpenAIRequest struct {
	Model       string    `json:"model"`
	Messages    []Message `json:"messages"`
	MaxTokens   int       `json:"max_tokens"`
	Temperature float64   `json:"temperature"`
}

type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type OpenAIResponse struct {
	Choices []struct {
		Message struct {
			Content string `json:"content"`
		} `json:"message"`
	} `json:"choices"`
}

// GetAIResponse 获取AI回复
func (s *AIService) GetAIResponse(userMessage string, conversationID uint) (string, error) {
	// 先尝试从FAQ中查找答案
	faqAnswer := s.searchFAQ(userMessage)
	if faqAnswer != "" {
		return faqAnswer, nil
	}

	// 如果FAQ中没有，则调用AI服务
	if s.cfg.AI.Provider == "openai" {
		return s.getOpenAIResponse(userMessage, conversationID)
	}

	// 默认回复
	return "抱歉，我暂时无法理解您的问题。请联系人工客服获取帮助。", nil
}

// searchFAQ 在FAQ中搜索答案
func (s *AIService) searchFAQ(question string) string {
	var faqs []models.FAQ
	database.GetDB().Where("status = ?", 1).Find(&faqs)

	question = strings.ToLower(question)

	for _, faq := range faqs {
		// 检查问题是否包含关键词
		keywords := strings.Split(faq.Keywords, ",")
		for _, keyword := range keywords {
			keyword = strings.TrimSpace(strings.ToLower(keyword))
			if keyword != "" && strings.Contains(question, keyword) {
				// 增加查看次数
				database.GetDB().Model(&faq).Update("view_count", faq.ViewCount+1)
				return faq.Answer
			}
		}

		// 检查是否与问题相似
		if strings.Contains(question, strings.ToLower(faq.Question)) ||
			strings.Contains(strings.ToLower(faq.Question), question) {
			database.GetDB().Model(&faq).Update("view_count", faq.ViewCount+1)
			return faq.Answer
		}
	}

	return ""
}

// getOpenAIResponse 调用OpenAI API
func (s *AIService) getOpenAIResponse(userMessage string, conversationID uint) (string, error) {
	// 获取历史对话记录
	var messages []models.Message
	database.GetDB().Where("conversation_id = ?", conversationID).
		Order("created_at ASC").
		Limit(10).
		Find(&messages)

	// 构建对话上下文
	chatMessages := []Message{
		{
			Role:    "system",
			Content: "你是马上来场站服务系统的智能客服助手。你需要帮助用户解答关于运单、排队叫号、场站服务等相关问题。请用简洁、友好的语气回答用户的问题。",
		},
	}

	// 添加历史消息
	for _, msg := range messages {
		role := "user"
		if msg.SenderType == "ai" {
			role = "assistant"
		}
		chatMessages = append(chatMessages, Message{
			Role:    role,
			Content: msg.Content,
		})
	}

	// 添加当前用户消息
	chatMessages = append(chatMessages, Message{
		Role:    "user",
		Content: userMessage,
	})

	// 构建请求
	reqBody := OpenAIRequest{
		Model:       s.cfg.AI.Model,
		Messages:    chatMessages,
		MaxTokens:   s.cfg.AI.MaxTokens,
		Temperature: s.cfg.AI.Temperature,
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return "", err
	}

	// 发送请求
	req, err := http.NewRequest("POST", s.cfg.AI.BaseURL+"/chat/completions", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", err
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+s.cfg.AI.APIKey)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("OpenAI API错误: %s", string(body))
	}

	// 解析响应
	var aiResp OpenAIResponse
	if err := json.Unmarshal(body, &aiResp); err != nil {
		return "", err
	}

	if len(aiResp.Choices) == 0 {
		return "", fmt.Errorf("AI未返回有效响应")
	}

	return aiResp.Choices[0].Message.Content, nil
}

