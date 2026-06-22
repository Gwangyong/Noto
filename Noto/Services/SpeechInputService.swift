//
//  SpeechInputService.swift
//  Noto
//

import AppKit
import AVFoundation
import Combine
import Foundation
import Speech

struct SpeechTranscript: Equatable {
    var text = ""

    static let empty = SpeechTranscript()

    var displayText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasText: Bool {
        !displayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@MainActor
final class SpeechInputService: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isRequestingPermission = false
    @Published private(set) var transcript = SpeechTranscript.empty
    @Published private(set) var errorMessage: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko-KR"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var activeRecognitionID: UUID?
    private var committedTranscript = ""
    private var currentRecognitionText = ""
    private var hasInstalledInputTap = false

    var canStartRecording: Bool {
        speechRecognizer?.isAvailable == true
    }

    func start() {
        guard !isRecording else { return }

        stopRecognition(resetTranscript: true, clearError: true)
        resetTranscript()
        errorMessage = nil
        isRecording = true
        isRequestingPermission = true

        requestPermissions { [weak self] isAllowed in
            guard let self else { return }
            self.isRequestingPermission = false
            guard self.isRecording else { return }

            guard isAllowed else {
                NSSound.beep()
                self.errorMessage = "마이크와 음성 인식 권한이 필요해요."
                self.stopRecognition(resetTranscript: true, clearError: false)
                return
            }

            self.startRecognition()
        }
    }

    @discardableResult
    func stop() -> SpeechTranscript {
        let finalTranscript = transcript
        stopRecognition(resetTranscript: false, clearError: false)
        return finalTranscript
    }

    func cancel() {
        stopRecognition(resetTranscript: true, clearError: true)
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
        guard isRecording else { return }
        guard canStartRecording else {
            NSSound.beep()
            errorMessage = "음성 인식을 사용할 수 없어요. 잠시 후 다시 시도해주세요."
            stopRecognition(resetTranscript: false, clearError: false)
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
        hasInstalledInputTap = true

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            NSSound.beep()
            errorMessage = "마이크를 시작할 수 없어요. 입력 장치를 확인해주세요."
            stopRecognition(resetTranscript: false, clearError: false)
            return
        }

        let recognitionID = UUID()
        activeRecognitionID = recognitionID
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognition(recognitionID: recognitionID, result: result, error: error)
            }
        }
    }

    private func handleRecognition(recognitionID: UUID, result: SFSpeechRecognitionResult?, error: Error?) {
        guard isRecording, activeRecognitionID == recognitionID else { return }

        if let recognizedText = result?.bestTranscription.formattedString {
            applyRecognizedText(recognizedText, isFinal: result?.isFinal == true)
        }

        if let error {
            #if DEBUG
            print("Noto speech recognition failed: \(error)")
            #endif
            errorMessage = "음성 인식에 문제가 생겼어요. 다시 시도해주세요."
            stopRecognition(resetTranscript: false, clearError: false)
        } else if result?.isFinal == true {
            restartRecognitionSession()
        }
    }

    private func applyRecognizedText(_ recognizedText: String, isFinal: Bool) {
        let cleanedText = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }

        if isFinal {
            committedTranscript = appendedTranscript(committedTranscript, cleanedText)
            currentRecognitionText = ""
        } else {
            currentRecognitionText = cleanedText
        }

        transcript = SpeechTranscript(
            text: appendedTranscript(committedTranscript, currentRecognitionText)
        )
    }

    private func restartRecognitionSession() {
        guard isRecording else { return }

        tearDownRecognitionResources()
        startRecognition()
    }

    private func stopRecognition(resetTranscript: Bool, clearError: Bool) {
        isRecording = false
        isRequestingPermission = false
        tearDownRecognitionResources()

        if resetTranscript {
            self.resetTranscript()
        }
        if clearError {
            errorMessage = nil
        }
    }

    private func tearDownRecognitionResources() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasInstalledInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledInputTap = false
        }
        recognitionRequest?.endAudio()
        let task = recognitionTask
        recognitionRequest = nil
        recognitionTask = nil
        activeRecognitionID = nil
        task?.cancel()
    }

    private func resetTranscript() {
        committedTranscript = ""
        currentRecognitionText = ""
        transcript = .empty
    }

    private func appendedTranscript(_ baseText: String, _ newText: String) -> String {
        guard !baseText.isEmpty else { return newText }
        guard !newText.isEmpty else { return baseText }
        guard baseText != newText else { return baseText }

        return "\(baseText) \(newText)"
    }

    deinit {
        audioEngine.stop()
        if hasInstalledInputTap {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
