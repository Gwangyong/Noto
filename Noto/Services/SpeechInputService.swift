//
//  SpeechInputService.swift
//  Noto
//

import AppKit
import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class SpeechInputService: ObservableObject {
    @Published private(set) var isRecording = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentTranscript = ""
    private var transcriptHandler: ((String) -> Void)?

    var canStartRecording: Bool {
        speechRecognizer?.isAvailable == true
    }

    func start(onTranscript: @escaping (String) -> Void) {
        guard !isRecording else { return }

        stopRecognition(resetTranscript: true)
        transcriptHandler = onTranscript
        currentTranscript = ""

        requestPermissions { [weak self] isAllowed in
            guard let self else { return }

            guard isAllowed else {
                NSSound.beep()
                self.stopRecognition(resetTranscript: true)
                return
            }

            self.startRecognition()
        }
    }

    @discardableResult
    func stop() -> String {
        let transcript = currentTranscript
        stopRecognition(resetTranscript: false)
        return transcript
    }

    func cancel() {
        stopRecognition(resetTranscript: true)
    }

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                Task { @MainActor in completion(false) }
                return
            }

            AVCaptureDevice.requestAccess(for: .audio) { microphoneAllowed in
                Task { @MainActor in completion(microphoneAllowed) }
            }
        }
    }

    private func startRecognition() {
        guard canStartRecording else {
            NSSound.beep()
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            NSSound.beep()
            stopRecognition(resetTranscript: true)
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognition(result: result, error: error)
            }
        }
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let transcript = result?.bestTranscription.formattedString {
            currentTranscript = transcript
            transcriptHandler?(transcript)
        }

        if error != nil {
            stopRecognition(resetTranscript: false)
        }
    }

    private func stopRecognition(resetTranscript: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        transcriptHandler = nil

        if resetTranscript {
            currentTranscript = ""
        }
    }

    deinit {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
