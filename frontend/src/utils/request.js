import axios from "axios";
import { ElMessage } from "element-plus";

const service = axios.create({
  baseURL: process.env.VUE_APP_BASE_API || "/api",
  timeout: 15000,
});

// 请求拦截器
service.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem("token");
    if (token) {
      config.headers["Authorization"] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    console.error("请求错误", error);
    return Promise.reject(error);
  }
);

// 响应拦截器
service.interceptors.response.use(
  (response) => {
    const res = response.data;

    if (res.code !== 0) {
      ElMessage({
        message: res.msg || "请求失败",
        type: "error",
        duration: 3000,
      });

      // token失效
      if (res.code === -100) {
        ElMessage({
          message: "登录已过期，请重新登录",
          type: "warning",
          duration: 3000,
        });
        // 可以在这里跳转到登录页或关闭窗口
      }

      return Promise.reject(new Error(res.msg || "请求失败"));
    } else {
      return res;
    }
  },
  (error) => {
    console.error("响应错误", error);
    ElMessage({
      message: error.message || "网络错误",
      type: "error",
      duration: 3000,
    });
    return Promise.reject(error);
  }
);

export default service;
