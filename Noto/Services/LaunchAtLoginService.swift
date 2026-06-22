//
//  LaunchAtLoginService.swift
//  Noto
//

import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginService {
    var isEnabledForSettings: Bool {
        switch SMAppService.mainApp.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }

    func setEnabled(_ isEnabled: Bool) throws -> Bool {
        if isEnabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
            return isEnabledForSettings
        }

        if isEnabledForSettings {
            try SMAppService.mainApp.unregister()
        }
        return false
    }
}
