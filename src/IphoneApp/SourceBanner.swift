//
//  SourceBanner.swift
//  通用的数据来源提示条：显示当前是 NAS 数据还是示例数据。
//

import SwiftUI

struct SourceBanner: View {
    let source: DataSource

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: source == .network ? "checkmark.circle.fill" : "info.circle.fill")
            Text(source == .network ? "正在显示 NAS 数据" : "当前显示示例数据（连接 NAS 后自动切换）")
            Spacer(minLength: 0)
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(10)
        .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
    }
}
