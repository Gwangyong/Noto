//
//  AppVersionService.swift
//  Noto
//

import Foundation

struct AppVersion {
    let marketingVersion: String
    let buildNumber: String

    var settingsDisplayText: String {
        "version \(marketingVersion)"
    }
}

enum AppVersionService {
    static var current: AppVersion {
        AppVersion(
            marketingVersion: bundleString(for: "CFBundleShortVersionString") ?? "-",
            buildNumber: bundleString(for: "CFBundleVersion") ?? "-"
        )
    }

    private static func bundleString(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}

enum NotoSupportLink {
    static let appID = "6782915254"

    static let feedbackForm = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSdjJzn9EhJdAtv8fqYKtTJnfdCpFq27B5F9sVvplzm2W9aKxQ/viewform")
    static let appPage = URL(string: "https://apps.apple.com/app/id\(appID)")
    static let writeReview = URL(string: "macappstore://itunes.apple.com/app/id\(appID)?action=write-review")
    static let webWriteReview = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")
}
