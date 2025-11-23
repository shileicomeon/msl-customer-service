import { defineStore } from "pinia";
import { ref } from "vue";

export const useUserStore = defineStore("user", () => {
  const token = ref("");
  const userInfo = ref(null);

  const setToken = (newToken) => {
    token.value = newToken;
    localStorage.setItem("token", newToken);
  };

  const setUserInfo = (info) => {
    userInfo.value = info;
    localStorage.setItem("userInfo", JSON.stringify(info));
  };

  const loadFromStorage = () => {
    const storedToken = localStorage.getItem("token");
    const storedUserInfo = localStorage.getItem("userInfo");

    if (storedToken) {
      token.value = storedToken;
    }

    if (storedUserInfo) {
      try {
        userInfo.value = JSON.parse(storedUserInfo);
      } catch (e) {
        console.error("解析用户信息失败", e);
      }
    }
  };

  const clear = () => {
    token.value = "";
    userInfo.value = null;
    localStorage.removeItem("token");
    localStorage.removeItem("userInfo");
  };

  return {
    token,
    userInfo,
    setToken,
    setUserInfo,
    loadFromStorage,
    clear,
  };
});
