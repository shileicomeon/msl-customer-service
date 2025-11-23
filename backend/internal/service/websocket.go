package service

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// 允许向对等方写入消息的时间
	writeWait = 10 * time.Second
	// 允许从对等方读取下一个pong消息的时间
	pongWait = 60 * time.Second
	// 在此期间向对等方发送ping
	pingPeriod = (pongWait * 9) / 10
	// 允许的最大消息大小
	maxMessageSize = 512 * 1024 // 512KB
)

// Client WebSocket客户端
type Client struct {
	Hub      *Hub
	Conn     *websocket.Conn
	Send     chan []byte
	UserID   uint
	SessionID string
}

// Hub WebSocket连接管理器
type Hub struct {
	Clients    map[*Client]bool
	Broadcast  chan []byte
	Register   chan *Client
	Unregister chan *Client
	mu         sync.RWMutex
}

var (
	hub  *Hub
	once sync.Once
)

// InitHub 初始化Hub
func InitHub() {
	once.Do(func() {
		hub = &Hub{
			Clients:    make(map[*Client]bool),
			Broadcast:  make(chan []byte),
			Register:   make(chan *Client),
			Unregister: make(chan *Client),
		}
	})
}

// GetHub 获取Hub实例
func GetHub() *Hub {
	return hub
}

// Run 运行Hub
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			h.Clients[client] = true
			h.mu.Unlock()
			log.Printf("客户端连接: UserID=%d, SessionID=%s", client.UserID, client.SessionID)

		case client := <-h.Unregister:
			h.mu.Lock()
			if _, ok := h.Clients[client]; ok {
				delete(h.Clients, client)
				close(client.Send)
				log.Printf("客户端断开: UserID=%d, SessionID=%s", client.UserID, client.SessionID)
			}
			h.mu.Unlock()

		case message := <-h.Broadcast:
			h.mu.RLock()
			for client := range h.Clients {
				select {
				case client.Send <- message:
				default:
					close(client.Send)
					delete(h.Clients, client)
				}
			}
			h.mu.RUnlock()
		}
	}
}

// SendToUser 发送消息给指定用户
func (h *Hub) SendToUser(userID uint, message []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	for client := range h.Clients {
		if client.UserID == userID {
			select {
			case client.Send <- message:
			default:
				close(client.Send)
				delete(h.Clients, client)
			}
		}
	}
}

// ReadPump 从WebSocket连接读取消息
func (c *Client) ReadPump() {
	defer func() {
		c.Hub.Unregister <- c
		c.Conn.Close()
	}()

	c.Conn.SetReadDeadline(time.Now().Add(pongWait))
	c.Conn.SetPongHandler(func(string) error {
		c.Conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket错误: %v", err)
			}
			break
		}

		// 处理接收到的消息
		var msg map[string]interface{}
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("消息解析错误: %v", err)
			continue
		}

		// 这里可以根据消息类型进行不同的处理
		// 例如：保存到数据库、调用AI服务等
		log.Printf("收到消息: UserID=%d, Message=%v", c.UserID, msg)
	}
}

// WritePump 向WebSocket连接写入消息
func (c *Client) WritePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)

			// 将队列中的消息一起发送
			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				return
			}

		case <-ticker.C:
			c.Conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

