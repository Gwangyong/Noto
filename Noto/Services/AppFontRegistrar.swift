//
//  AppFontRegistrar.swift
//  Noto
//

import CoreText
import Foundation

enum AppFontRegistrar {
    private static let fontFileNames = [
        "Pretendard-Regular",
        "Pretendard-Medium",
        "Pretendard-SemiBold"
    ]

    static func registerBundledFonts() {
        for fileName in fontFileNames {
            guard let url = bundledFontURL(fileName: fileName) else {
                continue
            }

            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func bundledFontURL(fileName: String) -> URL? {
        Bundle.main.url(forResource: fileName, withExtension: "otf", subdirectory: "Fonts")
            ?? Bundle.main.url(forResource: fileName, withExtension: "otf")
    }
}
