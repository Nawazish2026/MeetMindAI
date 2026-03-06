import Foundation
import Combine

// MARK: - AI ViewModel
/// Manages the speech-to-text and AI summary pipeline.
class AIViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var transcript: String = ""
    @Published var isTranscribing: Bool = false
    @Published var isGeneratingSummary: Bool = false
    @Published var summaryResult: AISummaryResult?
    @Published var errorMessage: String?

    // MARK: - Services
    private let speechService = SpeechRecognitionService()
    private let openAIService = OpenAIService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        // Sync transcription state from speech service
        speechService.$transcript
            .receive(on: RunLoop.main)
            .assign(to: &$transcript)

        speechService.$isTranscribing
            .receive(on: RunLoop.main)
            .assign(to: &$isTranscribing)
    }

    // MARK: - Transcribe Audio
    /// Transcribes the audio file at the given URL.
    func transcribeAudio(url: URL) {
        errorMessage = nil

        speechService.requestAuthorization { [weak self] authorized in
            guard let self = self else { return }

            if authorized {
                self.speechService.transcribeAudio(url: url) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let text):
                            self.transcript = text
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Speech recognition not authorized. Please enable it in Settings."
                }
            }
        }
    }

    // MARK: - Generate AI Summary
    /// Sends the transcript to Gemini AI and populates the summary result.
    func generateSummary() {
        guard !transcript.isEmpty else {
            errorMessage = "No transcript available to summarize."
            return
        }

        errorMessage = nil
        isGeneratingSummary = true

        Task {
            do {
                let result = try await openAIService.generateSummary(transcript: transcript)
                await MainActor.run {
                    self.summaryResult = result
                    self.isGeneratingSummary = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isGeneratingSummary = false
                }
            }
        }
    }

    // MARK: - Build Meeting
    /// Constructs a Meeting struct from the current state.
    func buildMeeting(
        title: String,
        duration: TimeInterval,
        audioFilePath: String
    ) -> Meeting {
        let actionItemsText = summaryResult?.actionItems.joined(separator: "\n• ") ?? ""
        let fullSummary = buildFullSummary()

        return Meeting(
            title: title,
            date: Date(),
            duration: duration,
            transcript: transcript,
            summary: fullSummary,
            actionItems: actionItemsText.isEmpty ? "" : "• \(actionItemsText)",
            audioFilePath: audioFilePath
        )
    }

    // MARK: - Full Summary Builder
    /// Combines all AI result sections into a single formatted string.
    private func buildFullSummary() -> String {
        guard let result = summaryResult else { return "" }

        var parts: [String] = []

        parts.append("📝 Summary\n\(result.summary)")

        if !result.keyPoints.isEmpty {
            let points = result.keyPoints.map { "• \($0)" }.joined(separator: "\n")
            parts.append("🔑 Key Points\n\(points)")
        }

        if !result.decisions.isEmpty {
            let decisions = result.decisions.map { "• \($0)" }.joined(separator: "\n")
            parts.append("✅ Decisions\n\(decisions)")
        }

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Reset
    func reset() {
        transcript = ""
        summaryResult = nil
        errorMessage = nil
        isTranscribing = false
        isGeneratingSummary = false
    }
}
