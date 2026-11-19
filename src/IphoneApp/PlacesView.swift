//
//  PlacesView.swift
//  地点：按城市聚类的卡片网格。
//

import SwiftUI

struct PlacesView: View {
    @EnvironmentObject private var store: PhotoStore

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SourceBanner(source: store.placeSource)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.places) { place in
                        NavigationLink(value: place) {
                            CollectionTile(
                                title: place.name,
                                subtitle: "\(place.count) 张",
                                coverURL: place.coverURL,
                                tintIndex: place.tintIndex,
                                systemImage: "map"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .navigationTitle("地点")
        .navigationDestination(for: Place.self) { place in
            PhotoCollectionView(title: place.name, photos: store.photos)
        }
    }
}
