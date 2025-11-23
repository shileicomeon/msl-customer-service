import request from "@/utils/request";

// 验证token
export function verifyToken(data) {
  return request({
    url: "/auth/verify",
    method: "post",
    data,
  });
}

// 获取用户信息
export function getUserInfo() {
  return request({
    url: "/user/info",
    method: "get",
  });
}

// 获取会话列表
export function getConversations() {
  return request({
    url: "/conversations",
    method: "get",
  });
}

// 获取消息列表
export function getMessages(sessionId) {
  return request({
    url: `/conversations/${sessionId}/messages`,
    method: "get",
  });
}

// 结束会话
export function endConversation(sessionId) {
  return request({
    url: `/conversations/${sessionId}/end`,
    method: "post",
  });
}

// 获取FAQ列表
export function getFAQList(params) {
  return request({
    url: "/faq/list",
    method: "get",
    params,
  });
}

// 获取FAQ分类
export function getFAQCategories() {
  return request({
    url: "/faq/categories",
    method: "get",
  });
}

// 提交反馈
export function submitFeedback(data) {
  return request({
    url: "/feedback",
    method: "post",
    data,
  });
}

// 上传文件
export function uploadFile(file) {
  const formData = new FormData();
  formData.append("file", file);
  return request({
    url: "/upload",
    method: "post",
    data: formData,
    headers: {
      "Content-Type": "multipart/form-data",
    },
  });
}
