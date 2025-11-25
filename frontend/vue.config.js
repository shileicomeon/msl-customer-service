const { defineConfig } = require("@vue/cli-service");

module.exports = defineConfig({
  transpileDependencies: true,
  publicPath: "/",
  outputDir: "dist",
  assetsDir: "static",
  lintOnSave: false,
  productionSourceMap: false,
  devServer: {
    host: "0.0.0.0",
    port: 8081,
    open: true,
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
        ws: true,
      },
      "/uploads": {
        target: "http://localhost:8080",
        changeOrigin: true,
      },
    },
  },
});
