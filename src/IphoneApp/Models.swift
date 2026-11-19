//
//  Models.swift
//  数据模型 + 本机配置 + 内置示例数据
//
//  注意：示例数据中的标题均为「示例xxx」，不包含任何真实信息；
//  真实 host / 账号 / 密码 / token 只来自用户在设置页的输入并保存在 UserDefaults。
//

import Foundation

// MARK: - 照片

/// 一张照片或视频的轻量模型，字段对齐绿联 NAS 相册 API 与电视版 MediaItem。
struct Photo: Identifiable, Hashable {
    let id: String
    let name: String
    let isVideo: Bool
    let thumbnailURL: String?
    let fullURL: String?
    let takenAt: String?
    /// 示例数据用的配色序号（0...5），仅用于无网络时的占位色块。
    let tintIndex: Int

    init(
        id: String = "",
        name: String = "",
        isVideo: Bool = false,
        thumbnailURL: String? = nil,
        fullURL: String? = nil,
        takenAt: String? = nil,
        tintIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isVideo = isVideo
        self.thumbnailURL = thumbnailURL
        self.fullURL = fullURL
        self.takenAt = takenAt
        self.tintIndex = tintIndex
    }

    /// 按月分组的 key，格式 yyyy-MM；无法解析时归入「未知」。
    var monthKey: String {
        guard let text = takenAt, text.count >= 7 else { return "未知" }
        let year = String(text.prefix(4))
        let monthStart = text.index(text.startIndex, offsetBy: 5)
        let monthEnd = text.index(monthStart, offsetBy: 2)
        let month = String(text[monthStart..<monthEnd])
        guard year.allSatisfy({ $0.isNumber }), month.allSatisfy({ $0.isNumber }) else { return "未知" }
        return "\(year)-\(month)"
    }

    /// 分组标题，例如「2025年12月」。
    var monthTitle: String {
        guard monthKey != "未知" else { return "未知时间" }
        let parts = monthKey.split(separator: "-")
        guard parts.count == 2, let month = Int(parts[1]) else { return monthKey }
        return "\(parts[0])年\(month)月"
    }
}

/// 一个月份分组（时间线的一节）。
struct PhotoMonth: Identifiable {
    let key: String
    let title: String
    let photos: [Photo]

    var id: String { key }
}

// MARK: - 相册 / 人物 / 地点

struct Album: Identifiable, Hashable {
    let id: String
    let name: String
    let photoCount: Int
    let coverURL: String?
    let tintIndex: Int

    init(id: String = "", name: String = "", photoCount: Int = 0,
         coverURL: String? = nil, tintIndex: Int = 0) {
        self.id = id
        self.name = name
        self.photoCount = photoCount
        self.coverURL = coverURL
        self.tintIndex = tintIndex
    }
}

struct Person: Identifiable, Hashable {
    let id: String
    let name: String
    let count: Int
    let avatarURL: String?
    let tintIndex: Int

    init(id: String = "", name: String = "", count: Int = 0,
         avatarURL: String? = nil, tintIndex: Int = 0) {
        self.id = id
        self.name = name
        self.count = count
        self.avatarURL = avatarURL
        self.tintIndex = tintIndex
    }
}

struct Place: Identifiable, Hashable {
    let id: String
    let name: String
    let count: Int
    let coverURL: String?
    let tintIndex: Int

    init(id: String = "", name: String = "", count: Int = 0,
         coverURL: String? = nil, tintIndex: Int = 0) {
        self.id = id
        self.name = name
        self.count = count
        self.coverURL = coverURL
        self.tintIndex = tintIndex
    }
}

// MARK: - 本机配置

/// 用户填写的连接信息。全部保存在 UserDefaults，仅存本机，不上传。
struct NASConfig: Codable, Equatable {
    var host: String = ""
    var port: String = "9443"
    var username: String = ""
    var password: String = ""
    var proxyPort: String = "8601"
    var token: String = ""

    private static let storageKey = "自用相册.连接配置.v1"

    /// 去掉用户可能粘贴的协议头、路径和端口，只保留纯主机。
    var cleanedHost: String {
        var value = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if let schemeRange = value.range(of: "://") {
            value = String(value[schemeRange.upperBound...])
        }
        if let slash = value.firstIndex(of: "/") {
            value = String(value[..<slash])
        }
        if let colon = value.firstIndex(of: ":") {
            value = String(value[..<colon])
        }
        return value
    }

    var isConfigured: Bool {
        !cleanedHost.isEmpty
            && !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    /// 设置页展示用的脱敏地址（由用户输入推导，代码本身不含任何地址）。
    var maskedHost: String {
        let value = cleanedHost
        guard !value.isEmpty else { return "未设置" }
        let parts = value.split(separator: ".")
        if parts.count == 4 {
            return "\(parts[0]).***.***.\(parts[3])"
        }
        let prefix = String(value.prefix(2))
        return prefix + "***"
    }

    static func load() -> NASConfig {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(NASConfig.self, from: data)
        else {
            return NASConfig()
        }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }
}

// MARK: - 内置示例数据（网络失败时兜底，保证界面永不空白）

enum DemoData {
    static let photos: [Photo] = {
        let times = [
            "2025-12-21 10:30:00", "2025-12-20 18:12:00", "2025-12-18 09:05:00",
            "2025-12-15 21:40:00", "2025-12-11 14:22:00",
            "2025-11-28 16:00:00", "2025-11-24 08:45:00", "2025-11-19 19:30:00",
            "2025-11-03 11:11:00",
            "2025-08-17 07:20:00", "2025-08-09 15:55:00", "2025-08-02 20:10:00",
        ]
        return times.enumerated().map { index, time in
            Photo(
                id: "demo-\(index)",
                name: "示例照片 \(index + 1)",
                isVideo: index == 3 || index == 9,
                takenAt: time,
                tintIndex: index % 6
            )
        }
    }()

    static let albums: [Album] = [
        Album(id: "demo-album-1", name: "示例相册 1", photoCount: 24, tintIndex: 0),
        Album(id: "demo-album-2", name: "示例相册 2", photoCount: 18, tintIndex: 1),
        Album(id: "demo-album-3", name: "示例相册 3", photoCount: 9, tintIndex: 2),
        Album(id: "demo-album-4", name: "示例相册 4", photoCount: 32, tintIndex: 3),
    ]

    static let people: [Person] = [
        Person(id: "demo-person-1", name: "示例人物 1", count: 18, tintIndex: 4),
        Person(id: "demo-person-2", name: "示例人物 2", count: 12, tintIndex: 5),
        Person(id: "demo-person-3", name: "示例人物 3", count: 7, tintIndex: 0),
        Person(id: "demo-person-4", name: "示例人物 4", count: 5, tintIndex: 1),
    ]

    static let places: [Place] = [
        Place(id: "demo-place-1", name: "示例城市 1", count: 21, tintIndex: 2),
        Place(id: "demo-place-2", name: "示例城市 2", count: 14, tintIndex: 3),
        Place(id: "demo-place-3", name: "示例城市 3", count: 8, tintIndex: 4),
        Place(id: "demo-place-4", name: "示例城市 4", count: 6, tintIndex: 5),
    ]
}
