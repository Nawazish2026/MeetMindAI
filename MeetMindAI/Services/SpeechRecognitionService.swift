import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognition Service
/// Handles converting audio files to text using Apple's Speech framework.
class SpeechRecognitionService: ObservableObject {

    // MARK: - Published Properties
    @Published var transcript: String = ""
    @Published var isTranscribing: Bool = false
    @Published var error: String?

    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    // MARK: - Request Authorization
    /// Requests speech recognition permission from the user.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    self.error = "Speech recognition permission denied."
                    completion(false)
                @unknown default:
                    self.error = "Unknown authorization status."
                    completion(false)
                }
            }
        }
    }

    // MARK: - Transcribe Audio File
    /// Transcribes a recorded audio file at the given URL.
    /// - Parameters:
    ///   - url: The file URL of the recorded audio.
    ///   - completion: Closure called with the final transcript or error.
    func transcribeAudio(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            let err = NSError(
                domain: "SpeechRecognition",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is not available."]
            )
            DispatchQueue.main.async {
                self.error = err.localizedDescription
            }
            completion(.failure(err))
            return
        }

        DispatchQueue.main.async {
            self.isTranscribing = true
            self.transcript = ""
            self.error = nil
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true

        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.isTranscribing = false
                    self.error = error.localizedDescription
                }
                completion(.failure(error))
                return
            }

            if let result = result {
                let text = result.bestTranscription.formattedString

                DispatchQueue.main.async {
                    self.transcript = text
                }

                // Final result — transcription is complete
                if result.isFinal {
                    DispatchQueue.main.async {
                        self.isTranscribing = false
                    }
                    completion(.success(text))
                }
            }
        }
    }
}
