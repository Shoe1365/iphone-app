//
//  PhotoCollectionView.swift
//  相册 / 人物 / 地点点进去后的照片网格（第一版复用已加载的照片列表）。
//

import SwiftUI

struct PhotoCollectionView: View {
    let title: String
    let photos: [Photo]

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        ScrollView {
            if photos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无照片")
                        .font(.headline)
                    Text("连接 NAS 后可查看真实照片。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(photos) { photo in
                        NavigationLink(value: photo) {
                            PhotoTile(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .padding(.bottom, 8)
        .navigationTitle(title)
        .navigationDestination(for: Photo.self) { photo in
            PhotoDetailView(photos: photos, initial: photo)
        }
    }
}
