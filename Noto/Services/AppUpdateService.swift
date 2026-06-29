//
//  AppUpdateService.swift
//  Noto
//

import Foundation

struct AppUpdateService {
    enum Status: Equatable {
        case upToDate(currentVersion: String)
        case updateAvailable(currentVersion: String, latestVersion: String, appStoreURL: URL?)
    }

    enum UpdateError: LocalizedError {
        case invalidLookupURL
        case invalidResponse
        case appNotFound

        var errorDescription: String? {
            switch self {
            case .invalidLookupURL:
                return "업데이트 확인 주소를 만들지 못했어요."
            case .invalidResponse:
                return "업데이트 정보를 읽지 못했어요."
            case .appNotFound:
                return "앱스토어에서 Noto 정보를 찾지 못했어요."
            }
        }
    }

    private let appID: String
    private let countryCode: String
    private let session: URLSession

    init(
        appID: String = NotoSupportLink.appID,
        countryCode: String = "kr",
        session: URLSession = .shared
    ) {
        self.appID = appID
        self.countryCode = countryCode
        self.session = session
    }

    func checkForUpdate(currentVersion: String) async throws -> Status {
        let latest = try await fetchLatestVersion()

        if VersionComparator.compare(latest.version, currentVersion) == .orderedDescending {
            return .updateAvailable(
                currentVersion: currentVersion,
                latestVersion: latest.version,
                appStoreURL: latest.appStoreURL ?? NotoSupportLink.appPage
            )
        }

        return .upToDate(currentVersion: currentVersion)
    }

    private func fetchLatestVersion() async throws -> AppStoreVersion {
        guard let lookupURL = lookupURL else {
            throw UpdateError.invalidLookupURL
        }

        let (data, response) = try await session.data(from: lookupURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw UpdateError.invalidResponse
        }

        let lookupResponse = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        guard let result = lookupResponse.results.first,
              !result.version.isEmpty
        else {
            throw UpdateError.appNotFound
        }

        return AppStoreVersion(version: result.version, appStoreURL: result.trackViewURL)
    }

    private var lookupURL: URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "id", value: appID),
            URLQueryItem(name: "country", value: countryCode)
        ]
        return components?.url
    }
}

private struct AppStoreVersion: Equatable {
    let version: String
    let appStoreURL: URL?
}

private struct AppStoreLookupResponse: Decodable {
    let results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Decodable {
    let version: String
    let trackViewURL: URL?

    enum CodingKeys: String, CodingKey {
        case version
        case trackViewURL = "trackViewUrl"
    }
}

private enum VersionComparator {
    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = numericParts(lhs)
        let rhsParts = numericParts(rhs)
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0..<count {
            let lhsValue = index < lhsParts.count ? lhsParts[index] : 0
            let rhsValue = index < rhsParts.count ? rhsParts[index] : 0

            if lhsValue > rhsValue {
                return .orderedDescending
            }
            if lhsValue < rhsValue {
                return .orderedAscending
            }
        }

        return .orderedSame
    }

    private static func numericParts(_ version: String) -> [Int] {
        version
            .split { !$0.isNumber }
            .compactMap { Int($0) }
    }
}
