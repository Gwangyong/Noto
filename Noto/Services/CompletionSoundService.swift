//
//  CompletionSoundService.swift
//  Noto
//

import AppKit
import Foundation

final class CompletionSoundService {
    func playIfEnabled(_ isEnabled: Bool) {
        guard isEnabled else { return }

        if let sound = NSSound(named: NSSound.Name("Glass")) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
