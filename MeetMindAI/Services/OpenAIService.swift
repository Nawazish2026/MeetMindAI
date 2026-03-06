import Foundation

// MARK: - API Keys
/// Reads the Gemini API key from the gitignored Secrets.swift file.
enum APIKeys {
    static let geminiKey = Secrets.geminiAPIKey
}

// MARK: - Gemini AI Service
/// Sends meeting transcripts to Google Gemini API and parses the AI-generated summary.
class OpenAIService: ObservableObject {

    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var error: String?
    @Published var result: AISummaryResult?

    // MARK: - Constants
    private let model = "gemini-2.0-flash"
    private var endpoint: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(APIKeys.geminiKey)"
    }

    // MARK: - System Prompt
    private let systemPrompt = """
    You are an AI meeting assistant.

    Analyze the following meeting transcript and generate a structured response in EXACTLY this format:

    SUMMARY:
    [A concise summary of the meeting]

    KEY POINTS:
    • [Point 1]
    • [Point 2]
    • [Point 3]

    ACTION ITEMS:
    • [Action item 1]
    • [Action item 2]

    DECISIONS:
    • [Decision 1]
    • [Decision 2]

    If there are no items for a section, write "None identified."
    """

    // MARK: - Generate Summary
    /// Sends the transcript to Gemini and returns a parsed AISummaryResult.
    func generateSummary(transcript: String) async throws -> AISummaryResult {
        await MainActor.run {
            self.isProcessing = true
            self.error = nil
            self.result = nil
        }

        guard let url = URL(string: endpoint) else {
            throw GeminiError.invalidURL
        }

        // Build the Gemini API request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "\(systemPrompt)\n\nPlease analyze this meeting transcript:\n\n\(transcript)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "maxOutputTokens": 2048
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Configure URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        // Perform network call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        // Parse the Gemini JSON response
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let candidates = json?["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parsingError
        }

        // Parse the structured response
        let summaryResult = parseResponse(text)

        await MainActor.run {
            self.isProcessing = false
            self.result = summaryResult
        }

        return summaryResult
    }

    // MARK: - Parse Response
    /// Parses the structured text response into an AISummaryResult.
    private func parseResponse(_ text: String) -> AISummaryResult {
        var summary = ""
        var keyPoints: [String] = []
        var actionItems: [String] = []
        var decisions: [String] = []

        let sections = text.components(separatedBy: "\n")
        var currentSection = ""

        for line in sections {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.uppercased().hasPrefix("SUMMARY:") {
                currentSection = "summary"
                let remaining = trimmed.replacingOccurrences(of: "SUMMARY:", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces)
                if !remaining.isEmpty { summary = remaining }
            } else if trimmed.uppercased().hasPrefix("KEY POINTS:") {
                currentSection = "keyPoints"
            } else if trimmed.uppercased().hasPrefix("ACTION ITEMS:") {
                currentSection = "actionItems"
            } else if trimmed.uppercased().hasPrefix("DECISIONS:") {
                currentSection = "decisions"
            } else if !trimmed.isEmpty {
                let cleanedLine = trimmed
                    .replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)

                switch currentSection {
                case "summary":
                    summary += (summary.isEmpty ? "" : " ") + cleanedLine
                case "keyPoints":
                    if !cleanedLine.isEmpty && cleanedLine != "None identified." {
                        keyPoints.append(cleanedLine)
                    }
                case "actionItems":
                    if !cleanedLine.isEmpty && cleanedLine != "None identified." {
                        actionItems.append(cleanedLine)
                    }
                case "decisions":
                    if !cleanedLine.isEmpty && cleanedLine != "None identified." {
                        decisions.append(cleanedLine)
                    }
                default:
                    break
                }
            }
        }

        return AISummaryResult(
            summary: summary.isEmpty ? "No summary available." : summary,
            keyPoints: keyPoints.isEmpty ? ["No key points identified."] : keyPoints,
            actionItems: actionItems.isEmpty ? ["No action items identified."] : actionItems,
            decisions: decisions.isEmpty ? ["No decisions identified."] : decisions
        )
    }
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parsingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .parsingError:
            return "Failed to parse the AI response."
        }
    }
}
