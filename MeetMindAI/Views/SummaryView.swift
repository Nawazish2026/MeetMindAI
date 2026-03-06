import SwiftUI

// MARK: - Summary View
/// Displays the AI-generated summary with key points, action items, and decisions.
struct SummaryView: View {

    @ObservedObject var aiViewModel: AIViewModel
    @ObservedObject var recorderViewModel: RecorderViewModel
    @ObservedObject var meetingViewModel: MeetingViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var meetingSaved = false
    @State private var showSaveConfirmation = false

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(hex: "0F0F1A") : Color(hex: "F8FAFC"))
                .ignoresSafeArea()

            if aiViewModel.isGeneratingSummary {
                processingView
            } else if let result = aiViewModel.summaryResult {
                summaryContentView(result: result)
            } else if let error = aiViewModel.errorMessage {
                errorView(message: error)
            }
        }
        .navigationTitle("AI Summary")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Meeting Saved!", isPresented: $showSaveConfirmation) {
            Button("View Meetings") {
                dismiss()
            }
        } message: {
            Text("Your meeting has been saved successfully with the AI summary.")
        }
    }

    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color(hex: "6366F1").opacity(0.08)
                            : Color(hex: "6366F1").opacity(0.06)
                    )
                    .frame(width: 130, height: 130)

                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color(hex: "8B5CF6").opacity(0.05)
                            : Color(hex: "8B5CF6").opacity(0.04)
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(ThemeColors.primaryGradient)
                    .symbolEffect(.pulse, isActive: true)
            }

            VStack(spacing: 8) {
                Text("Analyzing Meeting")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("AI is processing your transcript...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ProgressView()
                .tint(Color(hex: "6366F1"))
        }
    }

    // MARK: - Summary Content
    private func summaryContentView(result: AISummaryResult) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard(
                    icon: "doc.text.fill",
                    title: "Summary",
                    color: Color(hex: "3B82F6"),
                    content: result.summary
                )

                bulletCard(
                    icon: "key.fill",
                    title: "Key Points",
                    color: Color(hex: "F59E0B"),
                    items: result.keyPoints
                )

                bulletCard(
                    icon: "checkmark.circle.fill",
                    title: "Action Items",
                    color: Color(hex: "10B981"),
                    items: result.actionItems
                )

                bulletCard(
                    icon: "flag.fill",
                    title: "Decisions",
                    color: Color(hex: "8B5CF6"),
                    items: result.decisions
                )

                insightsCard

                if !meetingSaved {
                    saveMeetingButton
                }
            }
            .padding(16)
        }
    }

    // MARK: - Summary Card
    private func summaryCard(icon: String, title: String, color: Color, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }

            Text(content)
                .font(.body)
                .lineSpacing(4)
                .foregroundStyle(.primary.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1E1E2E") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 8)
        )
    }

    // MARK: - Bullet Card
    private func bulletCard(icon: String, title: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .foregroundStyle(color)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(color.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(item)
                            .font(.subheadline)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1E1E2E") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 8)
        )
    }

    // MARK: - Insights Card
    private var insightsCard: some View {
        HStack(spacing: 16) {
            insightItem(icon: "clock", label: "Duration", value: recorderViewModel.formattedTime, color: Color(hex: "3B82F6"))
            divider
            insightItem(icon: "text.word.spacing", label: "Words", value: "\(aiViewModel.transcript.split(separator: " ").count)", color: Color(hex: "8B5CF6"))
            divider
            insightItem(icon: "checkmark.circle", label: "Actions", value: "\(aiViewModel.summaryResult?.actionItems.count ?? 0)", color: Color(hex: "10B981"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1E1E2E") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 8)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: 1, height: 40)
    }

    private func insightItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "F59E0B"))

            Text("Summary Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Retry") {
                aiViewModel.generateSummary()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "6366F1"))
        }
    }

    // MARK: - Save Button
    private var saveMeetingButton: some View {
        Button {
            saveMeeting()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                Text("Save Meeting")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ThemeColors.successGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(hex: "10B981").opacity(0.3), radius: 12, y: 4)
        }
        .padding(.top, 8)
    }

    private func saveMeeting() {
        let meeting = aiViewModel.buildMeeting(
            title: recorderViewModel.meetingTitle,
            duration: recorderViewModel.currentTime,
            audioFilePath: recorderViewModel.audioFileURL?.path ?? ""
        )
        meetingViewModel.saveMeeting(meeting)
        meetingSaved = true
        showSaveConfirmation = true
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SummaryView(
            aiViewModel: AIViewModel(),
            recorderViewModel: RecorderViewModel(),
            meetingViewModel: MeetingViewModel()
        )
        .environmentObject(ThemeManager.shared)
    }
}
