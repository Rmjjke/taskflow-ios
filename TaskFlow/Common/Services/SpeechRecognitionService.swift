// SpeechRecognitionService.swift
// TaskFlow — Common / Services
//
// Real-time speech-to-text service for the Quick-Add dictation feature.
// Uses SFSpeechRecognizer + AVAudioEngine to stream microphone audio into
// a live transcription that populates the task title field.
//
// Permissions required (Info.plist):
//   NSMicrophoneUsageDescription
//   NSSpeechRecognitionUsageDescription

import Speech
import AVFoundation
import Observation

@Observable
@MainActor
final class SpeechRecognitionService {

    // MARK: - Observable State

    /// `true` while the audio engine is running and capturing speech.
    private(set) var isRecording: Bool = false

    /// Current permission state — checked on init, updated after `requestPermission()`.
    private(set) var permissionStatus: SFSpeechRecognizerAuthorizationStatus

    // MARK: - Private

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: .current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    // MARK: - Init

    init() {
        permissionStatus = SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Computed

    var isAvailable: Bool {
        recognizer?.isAvailable == true
    }

    var isPermitted: Bool {
        permissionStatus == .authorized
    }

    // MARK: - Permission

    /// Requests microphone + speech recognition authorization.
    /// Safe to call multiple times — no-ops when already authorized.
    func requestPermission() async {
        let status: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }
        permissionStatus = status
    }

    // MARK: - Recording

    /// Starts live transcription. `onUpdate` is called on `@MainActor` for every
    /// partial result. Recording auto-stops when `isFinal` fires or on error.
    func startRecording(onUpdate: @escaping @MainActor (String) -> Void) throws {
        stopRecording()

        // Configure audio session for recording
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Limit session to 60 seconds — prevents indefinite battery drain
        request.taskHint = .dictation
        recognitionRequest = request

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            // SFSpeechRecognitionTask callbacks arrive on an arbitrary thread;
            // hop to MainActor before touching @Observable state (Swift 6 safe).
            Task { @MainActor [weak self] in
                if let text = result?.bestTranscription.formattedString, !text.isEmpty {
                    onUpdate(text)
                }
                if result?.isFinal == true || error != nil {
                    self?.stopRecording()
                }
            }
        }

        // Tap the microphone input and feed buffers into the recognition request
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    /// Stops recording and cleans up all audio + recognition resources.
    func stopRecording() {
        guard isRecording || audioEngine.isRunning else { return }

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil

        isRecording = false

        // Deactivate audio session to restore playback for other apps
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}
