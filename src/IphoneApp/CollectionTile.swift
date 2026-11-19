//
//  CollectionTile.swift
//  相册 / 人物 / 地点 共用的卡片：封面 + 标题 + 数量。
//

import SwiftUI

struct CollectionTile: View {
    let title: String
    let subtitle: String
    let coverURL: String?
    let tintIndex: Int
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let urlString = coverURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .aspectRatio(4 / 3, contentMode: .fill)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var placeholder: some View {
        let colors = PhotoTile.palette[abs(tintIndex) % PhotoTile.palette.count]
        return ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: systemImage)
                .font(.title)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
