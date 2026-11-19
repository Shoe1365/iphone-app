//
//  SecureImage.swift
//  与 PhotoTile / PhotoDetailView / CollectionTile 共用的远程图片视图。
//  通过 ImageLoader 走信任自签证书的会话；失败时显示调用方给的占位视图。
//

import SwiftUI

struct SecureImage<Placeholder: View>: View {
    let urlString: String?
    var contentMode: ContentMode = .fill
    let placeholder: Placeholder

    @StateObject private var loader = ImageLoader()

    init(urlString: String?, contentMode: ContentMode = .fill,
         @ViewBuilder placeholder: () -> Placeholder) {
        self.urlString = urlString
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    var body: some View {
        ZStack {
            if let ui = loader.image {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
                if loader.isLoading {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        // URL 变化时自动取消旧任务并重新加载（滚动复用格子时不会串图）。
        .task(id: urlString) {
            await loader.load(urlString)
        }
    }
}
