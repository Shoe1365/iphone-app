//
//  PhotoDetailView.swift
//  全屏看图：左右滑动切换、点按显示/隐藏信息条。
//
//  横竖屏均使用 maxWidth/maxHeight + scaledToFit，不写死任何设备尺寸。
//

import SwiftUI

struct PhotoDetailView: View {
    let photos: [Photo]

    @State private var currentID: String
    @State private var showInfo = true
    @Environment(\.dismiss) private var dismiss

    init(photos: [Photo], initial: Photo) {
        self.photos = photos
        self._currentID = State(initialValue: initial.id)
    }

    private var currentIndex: Int {
        photos.firstIndex { $0.id == currentID } ?? 0
    }

    private var currentPhoto: Photo? {
        photos.indices.contains(currentIndex) ? photos[currentIndex] : nil
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentID) {
                ForEach(photos) { photo in
                    PhotoPage(photo: photo)
                        .tag(photo.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut) {
                    showInfo.toggle()
                }
            }

            VStack {
                topBar
                Spacer(minLength: 0)
                if showInfo {
                    infoBar
                }
            }
            // 该覆盖层只有按钮/文字有实际内容，空白区域的点击会自然透传给下层 TabView。
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
            .accessibilityLabel("返回")

            Spacer(minLength: 8)

            Text("\(currentIndex + 1) / \(photos.count)")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.45), in: Capsule())

            Spacer(minLength: 8)

            Button {
                withAnimation(.easeInOut) {
                    showInfo.toggle()
                }
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.45), in: Circle())
            }
            .accessibilityLabel("信息")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var infoBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(currentPhoto?.name ?? "")
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
            if let takenAt = currentPhoto?.takenAt {
                Text(takenAt)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            Text(currentPhoto?.isVideo == true ? "视频" : "照片")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

/// 单页图片：有网络图就加载，否则显示占位色块（示例数据）。
private struct PhotoPage: View {
    let photo: Photo

    var body: some View {
        Group {
            if let urlString = photo.fullURL ?? photo.thumbnailURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholder: some View {
        let colors = PhotoTile.palette[abs(photo.tintIndex) % PhotoTile.palette.count]
        return ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 14) {
                Image(systemName: photo.isVideo ? "video" : "photo")
                    .font(.largeTitle)
                Text(photo.name)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                Text("示例图片（连接 NAS 后显示真实照片）")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding()
        }
    }
}
