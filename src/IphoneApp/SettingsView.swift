//
//  SettingsView.swift
//  设置：脱敏地址、来源状态、清除缓存、关于说明、编辑/重置连接。
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PhotoStore

    @State private var showEdit = false
    @State private var showClearCache = false
    @State private var showReset = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    infoRow(title: "NAS 地址", value: store.config.maskedHost)
                    infoRow(title: "主服务端口", value: store.config.port)
                    infoRow(
                        title: "账号",
                        value: store.config.username.isEmpty ? "未设置" : store.config.username
                    )
                    Button {
                        showEdit = true
                    } label: {
                        Label("编辑连接设置", systemImage: "pencil")
                    }
                } header: {
                    Text("连接")
                } footer: {
                    Text("地址、端口、账号、密码和令牌只保存在本机，不上传。")
                }

                Section {
                    infoRow(title: "照片来源", value: store.photoSource.rawValue)
                    infoRow(title: "相册来源", value: store.albumSource.rawValue)
                    infoRow(title: "人物来源", value: store.peopleSource.rawValue)
                    infoRow(title: "地点来源", value: store.placeSource.rawValue)
                    Button(role: .destructive) {
                        showClearCache = true
                    } label: {
                        Label("清除本机缓存", systemImage: "trash")
                    }
                } header: {
                    Text("数据")
                }

                if !store.statusMessage.isEmpty {
                    Section {
                        Text(store.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("状态")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showReset = true
                    } label: {
                        Label("清除连接设置并退出登录", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } header: {
                    Text("关于")
                } footer: {
                    Text("自用 App，数据只在你手机和你的 NAS 之间。界面参考电视版 FN Photo，针对大屏 iPhone 与 iPad 自适应。")
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showEdit) {
                SetupView()
                    .environmentObject(store)
            }
            .alert("清除本机缓存", isPresented: $showClearCache) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    store.clearLocalData()
                }
            } message: {
                Text("将清除本机显示的数据并恢复示例数据，连接设置会保留。")
            }
            .alert("清除连接设置", isPresented: $showReset) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    store.resetConfiguration()
                }
            } message: {
                Text("清除后需要重新填写 NAS 地址与账号密码。")
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            Text(value)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}
