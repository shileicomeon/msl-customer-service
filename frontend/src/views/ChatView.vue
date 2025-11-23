<template>
  <div class="chat-container" :class="{ 'is-mobile': isMobile }">
    <!-- 头部 -->
    <div class="chat-header">
      <div class="header-left">
        <el-icon class="logo-icon"><Service /></el-icon>
        <span class="title">马上来智能客服</span>
      </div>
      <div class="header-right">
        <el-button v-if="!isMobile" text @click="showFAQ = true">
          <el-icon><QuestionFilled /></el-icon>
          常见问题
        </el-button>
        <el-button v-if="!isMobile" text @click="showFeedback = true">
          <el-icon><ChatDotRound /></el-icon>
          反馈
        </el-button>
        <el-dropdown v-else>
          <el-icon class="more-icon"><More /></el-icon>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="showFAQ = true">
                <el-icon><QuestionFilled /></el-icon>
                常见问题
              </el-dropdown-item>
              <el-dropdown-item @click="showFeedback = true">
                <el-icon><ChatDotRound /></el-icon>
                反馈
              </el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </div>
    </div>

    <!-- 消息列表 -->
    <div class="message-list" ref="messageListRef">
      <div v-if="messages.length === 0" class="empty-state">
        <el-icon class="empty-icon"><ChatLineRound /></el-icon>
        <p>您好！我是智能客服助手</p>
        <p class="sub-text">有什么可以帮您的吗？</p>
      </div>

      <div
        v-for="(message, index) in messages"
        :key="index"
        class="message-item"
        :class="message.type"
      >
        <div class="message-avatar">
          <el-avatar v-if="message.type === 'user'" :size="36">
            <el-icon><User /></el-icon>
          </el-avatar>
          <el-avatar v-else :size="36" style="background-color: #fa8f46">
            <el-icon><Service /></el-icon>
          </el-avatar>
        </div>
        <div class="message-content">
          <div class="message-bubble">
            <div
              v-if="message.messageType === 'text'"
              v-html="formatMessage(message.content)"
            ></div>
            <el-image
              v-else-if="message.messageType === 'image'"
              :src="message.fileUrl"
              fit="cover"
              style="max-width: 200px; border-radius: 8px"
              :preview-src-list="[message.fileUrl]"
            />
          </div>
          <div class="message-time">{{ formatTime(message.createdAt) }}</div>
        </div>
      </div>

      <div v-if="isTyping" class="message-item ai">
        <div class="message-avatar">
          <el-avatar :size="36" style="background-color: #fa8f46">
            <el-icon><Service /></el-icon>
          </el-avatar>
        </div>
        <div class="message-content">
          <div class="message-bubble typing">
            <span class="dot"></span>
            <span class="dot"></span>
            <span class="dot"></span>
          </div>
        </div>
      </div>
    </div>

    <!-- 输入框 -->
    <div class="input-area">
      <div class="input-tools">
        <el-upload
          :show-file-list="false"
          :before-upload="handleFileUpload"
          accept="image/*"
        >
          <el-button text>
            <el-icon><Picture /></el-icon>
          </el-button>
        </el-upload>
      </div>
      <el-input
        v-model="inputMessage"
        type="textarea"
        :rows="isMobile ? 2 : 3"
        placeholder="请输入您的问题..."
        @keydown.enter.exact="handleSendMessage"
        :disabled="!isConnected"
      />
      <el-button
        type="primary"
        :loading="isSending"
        :disabled="!inputMessage.trim() || !isConnected"
        @click="handleSendMessage"
      >
        发送
      </el-button>
    </div>

    <!-- FAQ对话框 -->
    <el-dialog
      v-model="showFAQ"
      title="常见问题"
      width="600px"
      :fullscreen="isMobile"
    >
      <div class="faq-list">
        <el-collapse>
          <el-collapse-item
            v-for="(faq, index) in faqList"
            :key="index"
            :title="faq.question"
            :name="index"
          >
            <div v-html="faq.answer"></div>
          </el-collapse-item>
        </el-collapse>
      </div>
    </el-dialog>

    <!-- 反馈对话框 -->
    <el-dialog
      v-model="showFeedback"
      title="意见反馈"
      width="500px"
      :fullscreen="isMobile"
    >
      <el-form :model="feedbackForm" label-width="80px">
        <el-form-item label="满意度">
          <el-rate v-model="feedbackForm.rating" />
        </el-form-item>
        <el-form-item label="反馈内容">
          <el-input
            v-model="feedbackForm.content"
            type="textarea"
            :rows="4"
            placeholder="请输入您的反馈..."
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showFeedback = false">取消</el-button>
        <el-button type="primary" @click="handleSubmitFeedback">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick, computed } from "vue";
import { ElMessage } from "element-plus";
import { WebSocketClient } from "@/utils/websocket";
import {
  verifyToken,
  getFAQList,
  submitFeedback,
  uploadFile,
} from "@/api/chat";
import { useUserStore } from "@/stores/user";
import dayjs from "dayjs";

const userStore = useUserStore();

// 响应式判断
const isMobile = ref(window.innerWidth <= 768);

// WebSocket
const ws = ref(null);
const isConnected = ref(false);

// 消息相关
const messages = ref([]);
const inputMessage = ref("");
const isSending = ref(false);
const isTyping = ref(false);
const messageListRef = ref(null);

// FAQ
const showFAQ = ref(false);
const faqList = ref([]);

// 反馈
const showFeedback = ref(false);
const feedbackForm = ref({
  rating: 5,
  content: "",
});

// 初始化
onMounted(async () => {
  // 监听窗口大小变化
  window.addEventListener("resize", handleResize);

  // 从URL获取token
  const urlParams = new URLSearchParams(window.location.search);
  const token = urlParams.get("token");
  const userMobile = urlParams.get("userMobile") || "";
  const userName = urlParams.get("userName") || "";

  if (!token) {
    ElMessage.error("缺少认证信息");
    return;
  }

  try {
    // 验证token
    const res = await verifyToken({
      token,
      userMobile,
      userName,
    });

    userStore.setToken(token);
    userStore.setUserInfo(res.data);

    // 连接WebSocket
    await connectWebSocket(token);

    // 加载FAQ
    loadFAQ();
  } catch (error) {
    ElMessage.error("初始化失败");
    console.error(error);
  }
});

onUnmounted(() => {
  window.removeEventListener("resize", handleResize);
  if (ws.value) {
    ws.value.close();
  }
});

// 连接WebSocket
async function connectWebSocket(token) {
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  const host = window.location.host;
  const wsUrl = `${protocol}//${host}/api/ws`;

  ws.value = new WebSocketClient(wsUrl, token);

  ws.value.onMessage((data) => {
    if (data.type === "system" || data.type === "ai") {
      isTyping.value = false;
      messages.value.push({
        type: data.type,
        content: data.content,
        messageType: "text",
        createdAt: new Date(),
      });
      scrollToBottom();
    }
  });

  try {
    await ws.value.connect();
    isConnected.value = true;
    ElMessage.success("连接成功");
  } catch (error) {
    ElMessage.error("连接失败");
    console.error(error);
  }
}

// 发送消息
function handleSendMessage(e) {
  if (e && e.shiftKey) {
    return;
  }
  e && e.preventDefault();

  const content = inputMessage.value.trim();
  if (!content || !isConnected.value) return;

  // 添加用户消息
  messages.value.push({
    type: "user",
    content,
    messageType: "text",
    createdAt: new Date(),
  });

  // 发送到服务器
  ws.value.send({
    type: "text",
    content,
  });

  inputMessage.value = "";
  isTyping.value = true;
  scrollToBottom();
}

// 文件上传
async function handleFileUpload(file) {
  try {
    const res = await uploadFile(file);

    // 添加图片消息
    messages.value.push({
      type: "user",
      content: "",
      messageType: "image",
      fileUrl: res.data.url,
      createdAt: new Date(),
    });

    // 发送到服务器
    ws.value.send({
      type: "image",
      content: res.data.url,
    });

    scrollToBottom();
  } catch (error) {
    ElMessage.error("上传失败");
  }
  return false;
}

// 加载FAQ
async function loadFAQ() {
  try {
    const res = await getFAQList();
    faqList.value = res.data || [];
  } catch (error) {
    console.error("加载FAQ失败", error);
  }
}

// 提交反馈
async function handleSubmitFeedback() {
  if (!feedbackForm.value.rating) {
    ElMessage.warning("请选择满意度");
    return;
  }

  try {
    await submitFeedback(feedbackForm.value);
    ElMessage.success("感谢您的反馈！");
    showFeedback.value = false;
    feedbackForm.value = {
      rating: 5,
      content: "",
    };
  } catch (error) {
    ElMessage.error("提交失败");
  }
}

// 滚动到底部
function scrollToBottom() {
  nextTick(() => {
    if (messageListRef.value) {
      messageListRef.value.scrollTop = messageListRef.value.scrollHeight;
    }
  });
}

// 格式化消息
function formatMessage(content) {
  return content.replace(/\n/g, "<br>");
}

// 格式化时间
function formatTime(time) {
  return dayjs(time).format("HH:mm");
}

// 处理窗口大小变化
function handleResize() {
  isMobile.value = window.innerWidth <= 768;
}
</script>

<style lang="scss" scoped>
.chat-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
  background-color: #f5f5f5;

  &.is-mobile {
    .chat-header {
      padding: 10px 15px;

      .title {
        font-size: 16px;
      }
    }

    .message-list {
      padding: 15px;
    }

    .input-area {
      padding: 10px;
    }
  }
}

.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  background-color: #fff;
  border-bottom: 1px solid #e4e7ed;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);

  .header-left {
    display: flex;
    align-items: center;
    gap: 10px;

    .logo-icon {
      font-size: 24px;
      color: #fa8f46;
    }

    .title {
      font-size: 18px;
      font-weight: 600;
      color: #303133;
    }
  }

  .header-right {
    display: flex;
    align-items: center;
    gap: 10px;

    .more-icon {
      font-size: 24px;
      cursor: pointer;
      color: #606266;
    }
  }
}

.message-list {
  flex: 1;
  overflow-y: auto;
  padding: 20px;

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    color: #909399;

    .empty-icon {
      font-size: 64px;
      margin-bottom: 20px;
      color: #dcdfe6;
    }

    p {
      margin: 5px 0;
      font-size: 16px;
    }

    .sub-text {
      font-size: 14px;
      color: #c0c4cc;
    }
  }

  .message-item {
    display: flex;
    margin-bottom: 20px;

    &.user {
      flex-direction: row-reverse;

      .message-content {
        align-items: flex-end;
      }

      .message-bubble {
        background-color: #fa8f46;
        color: #fff;
      }
    }

    &.ai,
    &.system {
      .message-bubble {
        background-color: #fff;
        color: #303133;
      }
    }

    .message-avatar {
      flex-shrink: 0;
      margin: 0 10px;
    }

    .message-content {
      display: flex;
      flex-direction: column;
      max-width: 60%;

      .message-bubble {
        padding: 10px 15px;
        border-radius: 12px;
        word-break: break-word;
        line-height: 1.6;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

        &.typing {
          display: flex;
          gap: 5px;
          padding: 15px 20px;

          .dot {
            width: 8px;
            height: 8px;
            background-color: #c0c4cc;
            border-radius: 50%;
            animation: typing 1.4s infinite;

            &:nth-child(2) {
              animation-delay: 0.2s;
            }

            &:nth-child(3) {
              animation-delay: 0.4s;
            }
          }
        }
      }

      .message-time {
        margin-top: 5px;
        font-size: 12px;
        color: #909399;
      }
    }
  }
}

@keyframes typing {
  0%,
  60%,
  100% {
    transform: translateY(0);
    opacity: 0.7;
  }
  30% {
    transform: translateY(-10px);
    opacity: 1;
  }
}

.input-area {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  padding: 15px 20px;
  background-color: #fff;
  border-top: 1px solid #e4e7ed;

  .input-tools {
    display: flex;
    align-items: center;
  }

  .el-textarea {
    flex: 1;
  }
}

.faq-list {
  max-height: 500px;
  overflow-y: auto;
}
</style>
