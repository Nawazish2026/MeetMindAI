import SwiftUI

// MARK: - Transcript View
/// Displays the speech-to-text transcription with a progress indicator.
struct TranscriptView: View {

    @ObservedObject var aiViewModel: AIViewModel
    @ObservedObject var recorderViewModel: RecorderViewModel
    @ObservedObject var meetingViewModel: MeetingViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSummary = false

    var body: some View {
        ZStack {
            // Adaptive background
            (colorScheme == .dark ? Color(hex: "0F0F1A") : Color(hex: "F8FAFC"))
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerCard
                    .padding(.top, 8)

                if aiViewModel.isTranscribing {
                    transcribingView
                } else if !aiViewModel.transcript.isEmpty {
                    transcriptContentView
                } else if let error = aiViewModel.errorMessage {
                    errorView(message: error)
                } else {
                    waitingView
                }

                Spacer()

                if !aiViewModel.transcript.isEmpty && !aiViewModel.isTranscribing {
                    generateSummaryButton
                }
            }
        }
        .navigationTitle("Transcript")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSummary) {
            SummaryView(
                aiViewModel: aiViewModel,
                recorderViewModel: recorderViewModel,
                meetingViewModel: meetingViewModel
            )
            .environmentObject(themeManager)
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "6366F1").opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Color(hex: "6366F1"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(recorderViewModel.meetingTitle)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label(recorderViewModel.formattedTime, systemImage: "clock")
                    Text("•")
                    Text(Date().formatted(date: .abbreviated, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1E1E2E") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 8)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Transcribing View
    private var transcribingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "6366F1").opacity(0.08))
                    .frame(width: 80, height: 80)

                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Color(hex: "6366F1"))
            }

            Text("Transcribing audio...")
                .font(.headline)
                .foregroundStyle(.secondary)

            if !aiViewModel.transcript.isEmpty {
                ScrollView {
                    Text(aiViewModel.transcript)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    // MARK: - Transcript Content
    private var transcriptContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(
                        "\(aiViewModel.transcript.split(separator: " ").count) words",
                        systemImage: "text.word.spacing"
                    )
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "6366F1").opacity(0.1))
                    .foregroundStyle(Color(hex: "6366F1"))
                    .clipShape(Capsule())

                    Spacer()

                    Button {
                        UIPasteboard.general.string = aiViewModel.transcript
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color(hex: "6366F1"))
                    }
                }

                Text(aiViewModel.transcript)
                    .font(.body)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "F59E0B"))

            Text("Transcription Error")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Try Again") {
                if let url = recorderViewModel.audioFileURL {
                    aiViewModel.transcribeAudio(url: url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "6366F1"))

            Spacer()
        }
    }

    // MARK: - Waiting View
    private var waitingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "6366F1"))
            Text("Preparing transcript...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Generate Summary Button
    private var generateSummaryButton: some View {
        Button {
            aiViewModel.generateSummary()
            showSummary = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Generate AI Summary")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ThemeColors.aiGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 12, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        TranscriptView(
            aiViewModel: AIViewModel(),
            recorderViewModel: RecorderViewModel(),
            meetingViewModel: MeetingViewModel()
        )
        .environmentObject(ThemeManager.shared)
    }
}
