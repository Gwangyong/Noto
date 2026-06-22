//
//  CompletionSoundService.swift
//  Noto
//

import AppKit
import Foundation

final class CompletionSoundService {
    private let sound: NSSound? = {
        if let soundURL = Bundle.main.url(forResource: "ping_custom", withExtension: "wav") {
            return NSSound(contentsOf: soundURL, byReference: false)
        }
        return NSSound(named: NSSound.Name("Ping"))
    }()

    func playIfEnabled(_ isEnabled: Bool) {
        guard isEnabled else { return }

        guard let sound else {
            NSSound.beep()
            return
        }

        if sound.isPlaying {
            sound.stop()
        }
        sound.currentTime = 0
        sound.play()
    }
}
