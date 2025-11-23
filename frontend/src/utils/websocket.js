export class WebSocketClient {
  constructor(url, token) {
    this.url = url;
    this.token = token;
    this.ws = null;
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 5;
    this.reconnectInterval = 3000;
    this.heartbeatInterval = 30000;
    this.heartbeatTimer = null;
    this.messageHandlers = [];
    this.isManualClose = false;
  }

  connect() {
    return new Promise((resolve, reject) => {
      try {
        const wsUrl = `${this.url}?token=${this.token}`;
        this.ws = new WebSocket(wsUrl);

        this.ws.onopen = () => {
          console.log("WebSocket连接成功");
          this.reconnectAttempts = 0;
          this.startHeartbeat();
          resolve();
        };

        this.ws.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data);
            this.messageHandlers.forEach((handler) => handler(data));
          } catch (e) {
            console.error("消息解析失败", e);
          }
        };

        this.ws.onerror = (error) => {
          console.error("WebSocket错误", error);
          reject(error);
        };

        this.ws.onclose = () => {
          console.log("WebSocket连接关闭");
          this.stopHeartbeat();

          if (
            !this.isManualClose &&
            this.reconnectAttempts < this.maxReconnectAttempts
          ) {
            this.reconnect();
          }
        };
      } catch (error) {
        reject(error);
      }
    });
  }

  reconnect() {
    this.reconnectAttempts++;
    console.log(
      `尝试重连... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`
    );

    setTimeout(() => {
      this.connect().catch((err) => {
        console.error("重连失败", err);
      });
    }, this.reconnectInterval);
  }

  startHeartbeat() {
    this.heartbeatTimer = setInterval(() => {
      if (this.ws && this.ws.readyState === WebSocket.OPEN) {
        this.send({ type: "ping" });
      }
    }, this.heartbeatInterval);
  }

  stopHeartbeat() {
    if (this.heartbeatTimer) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = null;
    }
  }

  send(data) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(data));
      return true;
    } else {
      console.error("WebSocket未连接");
      return false;
    }
  }

  onMessage(handler) {
    this.messageHandlers.push(handler);
  }

  close() {
    this.isManualClose = true;
    this.stopHeartbeat();
    if (this.ws) {
      this.ws.close();
      this.ws = null;
    }
  }
}
