import SwiftUI
import AVFoundation

// MARK: - Meeting Detail View
/// Comprehensive view showing audio playback, transcript, AI summary, and export.
struct MeetingDetailView: View {

    let meeting: Meeting
    @ObservedObject var meetingViewModel: MeetingViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTab: DetailTab = .summary
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackProgress: Double = 0
    @State private var playbackTimer: Timer?
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    @State private var showExportAlert = false

    enum DetailTab: String, CaseIterable {
        case summary = "Summary"
        case transcript = "Transcript"
        case actions = "Actions"
    }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(hex: "0F0F1A") : Color(hex: "F8FAFC"))
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    audioPlayerCard
                    tabPicker
                    tabContent
                }
                .padding(16)
            }
        }
        .navigationTitle(meeting.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { exportPDF() } label: {
                        Label("Export PDF", systemImage: "doc.fill")
                    }
                    Button { shareMeeting() } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        UIPasteboard.general.string = meeting.transcript
                    } label: {
                        Label("Copy Transcript", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color(hex: "6366F1"))
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheetView(activityItems: [url])
            }
        }
        .alert("PDF Exported", isPresented: $showExportAlert) {
            Button("Share") { showShareSheet = true }
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your meeting notes have been exported as a PDF.")
        }
        .onDisappear { stopAudio() }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label(meeting.fullDateString, systemImage: "calendar")
                Label(meeting.formattedDuration, systemImage: "clock")
                Label(
                    "\(meeting.transcript.split(separator: " ").count) words",
                    systemImage: "text.word.spacing"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            if !meeting.summary.isEmpty {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "F59E0B").opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "F59E0B"))
                    }
                    Text("AI Enhanced")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Audio Player Card
    private var audioPlayerCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "waveform")
                    .foregroundStyle(Color(hex: "6366F1"))
                Text("Audio Recording")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "6366F1").opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(ThemeColors.primaryGradient)
                        .frame(width: geometry.size.width * playbackProgress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text(formatTime(audioPlayer?.currentTime ?? 0))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Button { togglePlayback() } label: {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(ThemeColors.primaryGradient)
                }

                Spacer()

                Text(meeting.formattedDuration)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Card Background
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(hex: "1E1E2E") : Color.white)
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0 : 0.04), radius: 8)
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundStyle(selectedTab == tab ? Color(hex: "6366F1") : .secondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Color(hex: "6366F1") : Color.clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .summary:
            textContentCard(
                isEmpty: meeting.summary.isEmpty,
                emptyIcon: "sparkles",
                emptyTitle: "No Summary",
                emptyMessage: "AI summary was not generated for this meeting.",
                content: meeting.summary
            )
        case .transcript:
            textContentCard(
                isEmpty: meeting.transcript.isEmpty,
                emptyIcon: "doc.text",
                emptyTitle: "No Transcript",
                emptyMessage: "No transcript available for this meeting.",
                content: meeting.transcript
            )
        case .actions:
            actionsTabContent
        }
    }

    // MARK: - Text Content Card
    private func textContentCard(isEmpty: Bool, emptyIcon: String, emptyTitle: String, emptyMessage: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEmpty {
                emptyTabView(icon: emptyIcon, title: emptyTitle, message: emptyMessage)
            } else {
                Text(content)
                    .font(.body)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Actions Tab
    private var actionsTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if meeting.actionItems.isEmpty {
                emptyTabView(icon: "checkmark.circle", title: "No Action Items", message: "No action items were identified for this meeting.")
            } else {
                let items = meeting.actionItems
                    .components(separatedBy: "\n")
                    .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle")
                            .font(.caption)
                            .foregroundStyle(Color(hex: "10B981"))
                            .padding(.top, 3)

                        Text(item.replacingOccurrences(of: "• ", with: ""))
                            .font(.subheadline)
                            .lineSpacing(3)
                    }
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Empty Tab View
    private func emptyTabView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Audio Playback

    private func togglePlayback() {
        isPlaying ? pauseAudio() : playAudio()
    }

    private func playAudio() {
        guard !meeting.audioFilePath.isEmpty else { return }
        let url = URL(fileURLWithPath: meeting.audioFilePath)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)

            if audioPlayer == nil {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
            }

            audioPlayer?.play()
            isPlaying = true

            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let player = audioPlayer {
                    playbackProgress = player.currentTime / max(player.duration, 1)
                    if !player.isPlaying {
                        isPlaying = false
                        playbackTimer?.invalidate()
                    }
                }
            }
        } catch {
            print("❌ Playback error: \(error.localizedDescription)")
        }
    }

    private func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        playbackTimer?.invalidate()
        playbackProgress = 0
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func exportPDF() {
        pdfURL = PDFExporter.generatePDF(from: meeting)
        if pdfURL != nil { showExportAlert = true }
    }

    private func shareMeeting() {
        pdfURL = PDFExporter.generatePDF(from: meeting)
        if pdfURL != nil { showShareSheet = true }
    }
}

// MARK: - Share Sheet
struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MeetingDetailView(
            meeting: Meeting(
                title: "Sprint Planning",
                date: Date(),
                duration: 1920,
                transcript: "We discussed the upcoming sprint and assigned tasks to the team...",
                summary: "📝 Summary\nThe team reviewed the product roadmap and planned the next sprint.\n\n🔑 Key Points\n• Launch date confirmed for June\n• New features prioritized",
                actionItems: "• John will finalize UI design\n• Sarah will prepare launch blog\n• Mike will set up CI/CD pipeline",
                audioFilePath: ""
            ),
            meetingViewModel: MeetingViewModel()
        )
        .environmentObject(ThemeManager.shared)
    }
}
