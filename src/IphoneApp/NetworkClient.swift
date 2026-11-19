//
//  NetworkClient.swift
//  极薄网络层：只依赖 Foundation。
//
//  主数据走 HTTPS :9443，人物/地点只读代理走 HTTP :8601；
//  主机与端口全部来自用户在设置页填写的 NASConfig，代码中无任何固定地址。
//

import Foundation

// MARK: - 地址拼装

enum NASEndpoint {
    /// 主服务根地址，例如 https://<用户填写的主机>:<用户填写的端口>
    static func mainBase(_ config: NASConfig) -> URL? {
        let host = config.cleanedHost
        guard !host.isEmpty else { return nil }
        let port = config.port.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "9443"
            : config.port.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: "https://\(host):\(port)")
    }

    /// 人物/地点只读代理根地址，例如 http://<用户填写的主机>:<用户填写的代理端口>
    static func proxyBase(_ config: NASConfig) -> URL? {
        let host = config.cleanedHost
        guard !host.isEmpty else { return nil }
        let port = config.proxyPort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "8601"
            : config.proxyPort.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: "http://\(host):\(port)")
    }

    /// 在根地址后拼接路径与查询参数。path 不要以 / 开头。
    static func url(_ base: URL?, _ path: String, queryItems: [URLQueryItem] = []) -> URL? {
        guard let base = base else { return nil }
        let target = base.appendingPathComponent(path)
        guard var components = URLComponents(url: target, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }
}

// MARK: - 会话代理

/// 自用局域网 NAS 常用自签名证书；此代理仅放行服务端证书信任质询，
/// 其余质询仍按系统默认处理。所有连接目标仍完全由用户配置决定。
final class SelfSignedTLSDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - 请求封装

final class NetworkClient {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 20
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(
            configuration: configuration,
            delegate: SelfSignedTLSDelegate(),
            delegateQueue: nil
        )
    }

    func postJSON(_ url: URL, body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("FN Photo iPhone", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        return try await send(request)
    }

    func getJSON(_ url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("FN Photo iPhone", forHTTPHeaderField: "User-Agent")
        return try await send(request)
    }

    private func send(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(statusCode) else {
            throw NetworkError.http(statusCode)
        }
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = object as? [String: Any] else {
            throw NetworkError.badFormat
        }
        return dictionary
    }
}

enum NetworkError: LocalizedError {
    case http(Int)
    case badFormat
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .http(let code):
            return "HTTP \(code)"
        case .badFormat:
            return "返回数据格式无法识别"
        case .unexpectedResponse:
            return "返回内容异常"
        }
    }
}
