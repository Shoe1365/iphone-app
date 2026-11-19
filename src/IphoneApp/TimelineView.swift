//
//  TimelineView.swift
//  我的照片 · 时间线：按月分组的自适应网格。
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: PhotoStore

    /// adaptive 列数：大屏自动多列，小屏自动少列，不写死列数。
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                SourceBanner(source: store.photoSource)

                ForEach(store.monthGroups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(group.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer(minLength: 8)
                            Text("\(group.photos.count) 张")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(group.photos) { photo in
                                NavigationLink(value: photo) {
                                    PhotoTile(photo: photo)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("照片")
        .navigationDestination(for: Photo.self) { photo in
            PhotoDetailView(photos: store.photos, initial: photo)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await store.loadAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                .accessibilityLabel("刷新")
            }
        }
    }
}
