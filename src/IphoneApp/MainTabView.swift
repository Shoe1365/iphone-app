//
//  MainTabView.swift
//  底部五个标签：照片 / 相册 / 人物 / 地点 / 设置
//
//  TabView 由系统管理安全区，标签栏不会被 Home Indicator 遮挡。
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: PhotoStore

    var body: some View {
        TabView {
            NavigationStack {
                TimelineView()
            }
            .tabItem {
                Label("照片", systemImage: "photo.stack")
            }

            NavigationStack {
                AlbumsView()
            }
            .tabItem {
                Label("相册", systemImage: "rectangle.stack")
            }

            NavigationStack {
                PeopleView()
            }
            .tabItem {
                Label("人物", systemImage: "person.2")
            }

            NavigationStack {
                PlacesView()
            }
            .tabItem {
                Label("地点", systemImage: "map")
            }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
        .task {
            await store.loadAll()
        }
    }
}
