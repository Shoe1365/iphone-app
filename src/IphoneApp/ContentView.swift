//
//  ContentView.swift
//  根视图：未配置连接时显示设置/登录页，配置完成后显示主 Tab 导航。
//
//  所有连接信息都由用户在设置页填写，代码中不包含任何地址或凭据。
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PhotoStore

    var body: some View {
        Group {
            if store.isConfigured {
                MainTabView()
            } else {
                SetupView()
            }
        }
        .animation(.easeInOut, value: store.isConfigured)
    }
}
