//
//  PhotoStore.swift
//  唯一的数据源：读本机配置 → 请求 NAS API → 解析 → 发布；
//  任何一步失败都自动降级到内置示例数据，界面永不空白。
//

import Foundation

/// 当前界面显示的是真实 NAS 数据还是示例数据。
enum DataSource: String {
    case demo = "示例数据"
    case network = "NAS 数据"
}

@MainActor
final class PhotoStore: ObservableObject {
    // MARK: 配置
    @Published private(set) var config: NASConfig

    // MARK: 内容
    @Published var photos: [Photo] = DemoData.photos
    @Published var albums: [Album] = DemoData.albums
    @Published var people: [Person] = DemoData.people
    @Published var places: [Place] = DemoData.places

    // MARK: 来源与状态
    @Published var photoSource: DataSource = .demo
    @Published var albumSource: DataSource = .demo
    @Published var peopleSource: DataSource = .demo
    @Published var placeSource: DataSource = .demo
    @Published var isLoading = false
    @Published var statusMessage = ""

    private let client = NetworkClient()

    init() {
        self.config = NASConfig.load()
    }

    var isConfigured: Bool { config.isConfigured }

    /// 时间线：按月分组，月份倒序（新的在前）。
    var monthGroups: [PhotoMonth] {
        let grouped = Dictionary(grouping: photos) { $0.monthKey }
        return grouped.map { key, items in
            PhotoMonth(
                key: key,
                title: items.first?.monthTitle ?? key,
                photos: items.sorted { ($0.takenAt ?? "") > ($1.takenAt ?? "") }
            )
        }
        .sorted { $0.key > $1.key }
    }

    // MARK: - 配置操作

    /// 用户点「保存」时调用：写入 UserDefaults 并更新内存配置。
    func updateConfig(_ newConfig: NASConfig) {
        newConfig.save()
        config = newConfig
        statusMessage = "设置已保存到本机，仅存本机不上传"
    }

    /// 清除本机缓存：只还原显示内容，保留连接设置。
    func clearLocalData() {
        photos = DemoData.photos
        albums = DemoData.albums
        people = DemoData.people
        places = DemoData.places
        photoSource = .demo
        albumSource = .demo
        peopleSource = .demo
        placeSource = .demo
        statusMessage = "本机缓存已清除，已恢复示例数据"
    }

    /// 清除连接设置（设置页「退出/重置」用），让用户回到首次配置页。
    func resetConfiguration() {
        config.clear()
        config = NASConfig()
        statusMessage = "连接设置已清除"
    }

    // MARK: - 统一加载入口

    func loadAll() async {
        guard config.isConfigured else {
            statusMessage = "请先在设置中填写 NAS 信息"
            return
        }
        guard !config.token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            statusMessage = "尚未填写访问令牌，当前显示示例数据"
            return
        }

        isLoading = true
        defer { isLoading = false }

        // 四个来源彼此独立：某一路失败不影响其它标签页。
        await loadPhotos()
        await loadAlbums()
        await loadPeople()
        await loadPlaces()

        statusMessage = "已尝试从 NAS 更新；失败的部分继续使用示例数据"
    }

    // MARK: - 照片时间线

    private func loadPhotos() async {
        let tokenItem = URLQueryItem(name: "token", value: config.token)
        guard let url = NASEndpoint.url(
            NASEndpoint.mainBase(config),
            "ugreen/v5/photo/picture/timeline/list",
            queryItems: [tokenItem]
        ) else {
            fallbackPhotos()
            return
        }

        let body: [String: Any] = [
            "offset": 0,
            "limit": 1000,
            "sort_by": 0,
            "sort_order": 0,
            "total": 1,
            "type_option": ["all": 1],
            "range_option": ["personal": 1, "share": 1],
            "advanced_option": [:],
        ]

        do {
            let json = try await client.postJSON(url, body: body)
            guard (json["code"] as? Int) == 200 else { throw NetworkError.unexpectedResponse }
            let data = json["data"] as? [String: Any]
            let list = data?["list"] as? [[String: Any]] ?? []
            let items = list.compactMap { parsePhoto($0) }
            guard !items.isEmpty else { throw NetworkError.unexpectedResponse }
            photos = items.sorted { ($0.takenAt ?? "") > ($1.takenAt ?? "") }
            photoSource = .network
        } catch {
            fallbackPhotos()
        }
    }

    private func fallbackPhotos() {
        photos = DemoData.photos
        photoSource = .demo
    }

    /// 解析时间线条目，同时兼容主 API 与 8601 代理返回的字段命名。
    private func parsePhoto(_ dict: [String: Any]) -> Photo? {
        let rawID = dict["picture_id"] ?? dict["id"]
        let id: String
        if let number = rawID as? NSNumber {
            id = number.stringValue
        } else if let text = rawID as? String {
            id = text
        } else {
            return nil
        }
        guard !id.isEmpty, id != "0" else { return nil }

        let showType = (dict["show_type"] as? Int) ?? (dict["showType"] as? Int) ?? 0
        let isVideo = showType == 1 || showType == 2
        let name = (dict["file_name"] as? String)
            ?? (dict["name"] as? String)
            ?? "照片 \(id)"
        let takenAt = formatEpoch(dict["create_time_utc"]) ?? (dict["takenAt"] as? String)

        return Photo(
            id: id,
            name: name,
            isVideo: isVideo,
            thumbnailURL: streamURL(id: id, sizeType: 1),
            fullURL: streamURL(id: id, sizeType: isVideo ? 6 : 3),
            takenAt: takenAt,
            tintIndex: abs(id.hashValue % 6)
        )
    }

    private func formatEpoch(_ value: Any?) -> String? {
        var seconds: TimeInterval?
        if let number = value as? NSNumber {
            seconds = number.doubleValue
        } else if let text = value as? String {
            seconds = Double(text)
        }
        guard let interval = seconds, interval > 0 else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter.string(from: Date(timeIntervalSince1970: interval))
    }

    /// 根据当前配置动态拼出图片流地址，绝不写死主机或 token。
    private func streamURL(id: String, sizeType: Int) -> String? {
        guard let base = NASEndpoint.mainBase(config) else { return nil }
        let encodedToken = config.token.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? config.token
        return "\(base.absoluteString)/ugreen/v5/photo/picture/stream"
            + "?id=\(id)&size_type=\(sizeType)&client_id=IPHONE&token=\(encodedToken)"
    }

    // MARK: - 相册

    private func loadAlbums() async {
        guard let url = NASEndpoint.url(
            NASEndpoint.mainBase(config),
            "ugreen/v5/photo/album/list",
            queryItems: [URLQueryItem(name: "token", value: config.token)]
        ) else {
            fallbackAlbums()
            return
        }

        do {
            let json = try await client.postJSON(url, body: [:])
            guard (json["code"] as? Int) == 200 else { throw NetworkError.unexpectedResponse }
            let data = json["data"] as? [String: Any]
            let list = data?["result"] as? [[String: Any]] ?? []
            let items: [Album] = list.compactMap { dict in
                guard let name = dict["album_name"] as? String, !name.isEmpty else { return nil }
                let identifier = (dict["album_uuid"] as? String) ?? name
                let coverID = ((dict["cover"] as? [String: Any])?["picture_id"] as? NSNumber)?.stringValue
                return Album(
                    id: identifier,
                    name: name,
                    photoCount: (dict["total"] as? Int) ?? 0,
                    coverURL: coverID.flatMap { streamURL(id: $0, sizeType: 1) },
                    tintIndex: abs(identifier.hashValue % 6)
                )
            }
            guard !items.isEmpty else { throw NetworkError.unexpectedResponse }
            albums = items
            albumSource = .network
        } catch {
            fallbackAlbums()
        }
    }

    private func fallbackAlbums() {
        albums = DemoData.albums
        albumSource = .demo
    }

    // MARK: - 人物（8601 只读代理）

    private func loadPeople() async {
        guard let url = NASEndpoint.url(NASEndpoint.proxyBase(config), "api/people") else {
            fallbackPeople()
            return
        }

        do {
            let json = try await client.getJSON(url)
            guard (json["code"] as? Int) == 200 else { throw NetworkError.unexpectedResponse }
            let list = json["data"] as? [[String: Any]] ?? []
            let items: [Person] = list.compactMap { dict in
                let rawID = dict["id"] ?? dict["faceId"]
                let identifier: String
                if let number = rawID as? NSNumber {
                    identifier = number.stringValue
                } else if let text = rawID as? String {
                    identifier = text
                } else {
                    return nil
                }
                guard !identifier.isEmpty, identifier != "0" else { return nil }

                let rawName = dict["name"] as? String ?? ""
                let name = rawName.isEmpty ? "未命名人物 \(identifier)" : rawName
                let cover = dict["cover"] as? NSNumber
                return Person(
                    id: identifier,
                    name: name,
                    count: (dict["count"] as? Int) ?? 0,
                    avatarURL: cover.flatMap { streamURL(id: $0.stringValue, sizeType: 1) },
                    tintIndex: abs(identifier.hashValue % 6)
                )
            }
            guard !items.isEmpty else { throw NetworkError.unexpectedResponse }
            people = items
            peopleSource = .network
        } catch {
            fallbackPeople()
        }
    }

    private func fallbackPeople() {
        people = DemoData.people
        peopleSource = .demo
    }

    // MARK: - 地点（8601 只读代理）

    private func loadPlaces() async {
        guard let url = NASEndpoint.url(NASEndpoint.proxyBase(config), "api/locations") else {
            fallbackPlaces()
            return
        }

        do {
            let json = try await client.getJSON(url)
            guard (json["code"] as? Int) == 200 else { throw NetworkError.unexpectedResponse }
            let list = json["data"] as? [[String: Any]] ?? []
            let items: [Place] = list.compactMap { dict in
                guard let city = dict["city"] as? String, !city.isEmpty else { return nil }
                let cover = dict["cover"] as? NSNumber
                return Place(
                    id: city,
                    name: city,
                    count: (dict["count"] as? Int) ?? 0,
                    coverURL: cover.flatMap { streamURL(id: $0.stringValue, sizeType: 1) },
                    tintIndex: abs(city.hashValue % 6)
                )
            }
            guard !items.isEmpty else { throw NetworkError.unexpectedResponse }
            places = items
            placeSource = .network
        } catch {
            fallbackPlaces()
        }
    }

    private func fallbackPlaces() {
        places = DemoData.places
        placeSource = .demo
    }
}
