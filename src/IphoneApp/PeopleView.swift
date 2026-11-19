//
//  PeopleView.swift
//  人物相册：人脸聚类卡片网格。
//

import SwiftUI

struct PeopleView: View {
    @EnvironmentObject private var store: PhotoStore

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SourceBanner(source: store.peopleSource)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(store.people) { person in
                        NavigationLink(value: person) {
                            VStack(spacing: 8) {
                                ZStack {
                                    if let urlString = person.avatarURL, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable().scaledToFill()
                                            default:
                                                avatarPlaceholder(for: person)
                                            }
                                        }
                                    } else {
                                        avatarPlaceholder(for: person)
                                    }
                                }
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .clipShape(Circle())

                                Text(person.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text("\(person.count) 张")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .navigationTitle("人物")
        .navigationDestination(for: Person.self) { person in
            PhotoCollectionView(title: person.name, photos: store.photos)
        }
    }

    private func avatarPlaceholder(for person: Person) -> some View {
        let colors = PhotoTile.palette[abs(person.tintIndex) % PhotoTile.palette.count]
        return ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "person.fill")
                .font(.title)
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
