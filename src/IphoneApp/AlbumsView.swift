//
//  AlbumsView.swift
//  我的相册：卡片网格，点击进入照片列表。
//

import SwiftUI

struct AlbumsView: View {
    @EnvironmentObject private var store: PhotoStore

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SourceBanner(source: store.albumSource)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.albums) { album in
                        NavigationLink(value: album) {
                            CollectionTile(
                                title: album.name,
                                subtitle: "\(album.photoCount) 张",
                                coverURL: album.coverURL,
                                tintIndex: album.tintIndex,
                                systemImage: "rectangle.stack"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .navigationTitle("相册")
        .navigationDestination(for: Album.self) { album in
            PhotoCollectionView(title: album.name, photos: store.photos)
        }
    }
}
