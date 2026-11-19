//
//  IphoneAppApp.swift
//  自用 iPhone 相册 —— 应用入口
//
//  仅使用系统框架（SwiftUI + Foundation），无第三方依赖。
//

import SwiftUI

@main
struct IphoneAppApp: App {
    @StateObject private var store = PhotoStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
