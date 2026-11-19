//
//  PhotoTile.swift
//  可复用的照片格子：正方形、列宽自适应、网络图加载失败时用占位色块。
//

import SwiftUI

struct PhotoTile: View {
    let photo: Photo

    /// 占位配色只用于示例/无网络场景，不含任何真实信息。
    static let palette: [[Color]] = [
        [.blue.opacity(0.8), .purple.opacity(0.8)],
        [.green.opacity(0.8), .teal.opacity(0.8)],
        [.orange.opacity(0.85), .pink.opacity(0.8)],
        [.indigo.opacity(0.8), .blue.opacity(0.7)],
        [.red.opacity(0.75), .orange.opacity(0.8)],
        [.gray.opacity(0.8), .blue.opacity(0.65)],
    ]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            content
            if photo.isVideo {
                Image(systemName: "video.fill")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.black.opacity(0.5), in: Circle())
                    .padding(8)
            }
        }
        // 用宽高比而非固定尺寸：大屏 iPhone / iPad 上由列宽自动决定格子大小。
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var content: some View {
        // 用 SecureImage 走自签证书信任会话；原生 AsyncImage 会让所有 NAS 图片加载失败。
        SecureImage(urlString: photo.thumbnailURL) {
            placeholder
        }
    }

    private var placeholder: some View {
        let colors = Self.palette[abs(photo.tintIndex) % Self.palette.count]
        return ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 6) {
                Image(systemName: photo.isVideo ? "video" : "photo")
                    .font(.title2)
                Text(photo.name)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
            }
            .foregroundColor(.white.opacity(0.92))
        }
    }
}
