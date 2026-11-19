//
//  ImageLoader.swift
//  远程图片加载器。
//
//  为什么不用 SwiftUI 的 AsyncImage：AsyncImage 内部使用系统默认 URLSession，
//  无法注入 URLSessionDelegate，家用 NAS 的自签名证书会被系统一律拒绝，
//  导致照片全部加载失败。这里复用 NetworkClient 中信任自签证书的会话，
//  并加一层内存缓存，避免网格滚动时反复下载。
//

import Foundation
import SwiftUI

@MainActor
final class ImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var failed = false
    @Published private(set) var isLoading = false

    private static let cache = NSCache<NSString, UIImage>()

    /// 加载指定 URL 的图片；失败时只置 failed，不抛异常、不影响界面。
    func load(_ urlString: String?) async {
        image = nil
        failed = false
        guard let urlString, let url = URL(string: urlString) else {
            failed = true
            return
        }

        let key = urlString as NSString
        if let cached = Self.cache.object(forKey: key) {
            image = cached
            return
        }

        isLoading = true
        do {
            let data = try await NetworkClient.shared.imageData(url)
            if let ui = UIImage(data: data) {
                Self.cache.setObject(ui, forKey: key)
                image = ui
            } else {
                failed = true
            }
        } catch {
            failed = true
        }
        isLoading = false
    }
}
