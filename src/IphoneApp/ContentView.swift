//
//  ContentView.swift
//  第一版：验证整条「Windows 写代码 → 云端编译 → 装进 iPhone」流程能否跑通。
//  界面只有一个标题和一个按钮，不做任何实际功能。
//

import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("自用 App 跑起来了")
                .font(.title)
                .fontWeight(.bold)

            Text("按钮点击次数：\(count)")
                .font(.title2)
                .foregroundColor(.secondary)

            Button("点我 +1") {
                count += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
