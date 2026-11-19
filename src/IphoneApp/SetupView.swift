//
//  SetupView.swift
//  首次打开 / 编辑连接：所有字段由用户填写，只保存在本机。
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var store: PhotoStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft = NASConfig()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("NAS 主机地址（局域网 IP 或域名）", text: $draft.host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("主服务端口（默认 9443）", text: $draft.port)
                        .keyboardType(.numberPad)
                    TextField("账号", text: $draft.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("密码", text: $draft.password)
                } header: {
                    Text("连接 NAS")
                } footer: {
                    Text("只保存在本机，不上传。地址、账号、密码全部由你填写，App 内不含任何预设凭据。")
                }

                Section {
                    TextField("人物/地点代理端口（默认 8601）", text: $draft.proxyPort)
                        .keyboardType(.numberPad)
                    SecureField("访问令牌（可选，用于读取照片）", text: $draft.token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("可选")
                } footer: {
                    Text("不填访问令牌也能进入 App，此时会显示内置示例数据。")
                }

                Section {
                    Button {
                        store.updateConfig(draft)
                        dismiss()
                        Task { await store.loadAll() }
                    } label: {
                        HStack {
                            Spacer()
                            Label("保存到本机并进入", systemImage: "checkmark.circle.fill")
                            Spacer()
                        }
                    }
                    .disabled(!draft.isConfigured)
                }

                if !store.statusMessage.isEmpty {
                    Section {
                        Text(store.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("连接设置")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // 从编辑入口进来时用当前配置预填；首次进入保持空白。
                if draft.host.isEmpty {
                    draft = store.config
                }
            }
        }
    }
}
