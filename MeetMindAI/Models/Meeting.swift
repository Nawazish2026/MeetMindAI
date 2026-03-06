import Foundation

// MARK: - Meeting Model
/// Lightweight value type representing a meeting.
/// Used across ViewModels and Views; mapped to/from CoreData's MeetingEntity.
struct Meeting: Identifiable, Hashable {
    let id: UUID
    var title: String
    var date: Date
    var duration: TimeInterval
    var transcript: String
    var summary: String
    var actionItems: String
    var audioFilePath: String

    init(
        id: UUID = UUID(),
        title: String = "New Meeting",
        date: Date = Date(),
        duration: TimeInterval = 0,
        transcript: String = "",
        summary: String = "",
        actionItems: String = "",
        audioFilePath: String = ""
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.transcript = transcript
        self.summary = summary
        self.actionItems = actionItems
        self.audioFilePath = audioFilePath
    }
}

// MARK: - AI Summary Result
/// Parsed result returned by the Gemini AI service.
struct AISummaryResult {
    var summary: String
    var keyPoints: [String]
    var actionItems: [String]
    var decisions: [String]
}

// MARK: - Formatted Helpers
extension Meeting {
    /// Human-readable duration string (e.g. "12:34").
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Relative date string (e.g. "Today", "Yesterday", "Mar 5").
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Full date string for detail views.
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
