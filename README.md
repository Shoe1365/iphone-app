# 自用 iPhone App

Windows 上写 SwiftUI，GitHub Actions 云端编译，SideStore 免费签名装到自己的 iPhone。
不上架 App Store，不买开发者账号，不买 Mac。

## 仓库结构

```
src/                      SwiftUI 源码 + XcodeGen 配置
  project.yml             项目描述（生成 Xcode 工程）
  IphoneApp/              源码
    IphoneAppApp.swift    App 入口
    ContentView.swift     第一个界面
.github/workflows/
  build.yml               云端编译配置
```

## 怎么更新 App

1. 改 `src/IphoneApp/` 里的 Swift 文件
2. 提交并推送：
   ```
   git add .
   git commit -m "更新说明"
   git push
   ```
3. GitHub Actions 自动编译，完成后在 Actions 页面下载 `IphoneApp-unsigned` 里的 IPA
4. 用 SideStore 安装到 iPhone

## 编译产物

- 名称：`IphoneApp.ipa`（unsigned，需在 iPhone 上用 SideStore 签名）
- 保留：7 天，过期可重新跑 Actions 生成
