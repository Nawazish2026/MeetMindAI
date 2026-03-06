import SwiftUI

// MARK: - Record View
/// Full-screen recording interface with timer, waveform animation, and controls.
/// Always uses a dark immersive theme regardless of app theme setting.
struct RecordView: View {

    @StateObject private var viewModel = RecorderViewModel()
    @StateObject private var aiViewModel = AIViewModel()
    @ObservedObject var meetingViewModel: MeetingViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showTranscript = false
    @State private var pulseAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Always-dark immersive recording background
                LinearGradient(
                    colors: [Color(hex: "0D0D1A"), Color(hex: "1A0A2E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Subtle radial glow behind timer
                RadialGradient(
                    colors: [
                        viewModel.state == .recording
                            ? Color(hex: "EF4444").opacity(0.08)
                            : Color(hex: "6366F1").opacity(0.06),
                        .clear
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    // Title field
                    TextField("Meeting Title", text: $viewModel.meetingTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)

                    Spacer()

                    // Timer display
                    timerView

                    // Waveform visualization
                    waveformView
                        .frame(height: 80)
                        .padding(.horizontal, 30)

                    Spacer()

                    // Recording state label
                    stateLabel

                    // Control buttons
                    controlButtons
                        .padding(.bottom, 50)
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if viewModel.state != .idle {
                            viewModel.stopRecording()
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .navigationDestination(isPresented: $showTranscript) {
                TranscriptView(
                    aiViewModel: aiViewModel,
                    recorderViewModel: viewModel,
                    meetingViewModel: meetingViewModel
                )
                .environmentObject(themeManager)
            }
            .onChange(of: viewModel.recordingCompleted) { _, completed in
                if completed, let url = viewModel.audioFileURL {
                    aiViewModel.transcribeAudio(url: url)
                    showTranscript = true
                }
            }
        }
    }

    // MARK: - Timer View
    private var timerView: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(
                    viewModel.state == .recording
                        ? Color(hex: "EF4444").opacity(0.3)
                        : Color.white.opacity(0.08),
                    lineWidth: 2
                )
                .frame(width: 210, height: 210)
                .scaleEffect(pulseAnimation && viewModel.state == .recording ? 1.15 : 1.0)
                .animation(
                    viewModel.state == .recording
                        ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        : .default,
                    value: pulseAnimation
                )

            // Middle ring
            Circle()
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                .frame(width: 190, height: 190)

            // Inner fill
            Circle()
                .fill(
                    viewModel.state == .recording
                        ? Color(hex: "EF4444").opacity(0.08)
                        : Color.white.opacity(0.03)
                )
                .frame(width: 180, height: 180)

            // Time text
            VStack(spacing: 6) {
                Text(viewModel.formattedTime)
                    .font(.system(size: 48, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.white)

                Text(stateText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(stateColor.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(2)
            }
        }
        .onAppear { pulseAnimation = true }
    }

    private var stateText: String {
        switch viewModel.state {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .paused: return "Paused"
        }
    }

    private var stateColor: Color {
        switch viewModel.state {
        case .idle: return .white
        case .recording: return Color(hex: "EF4444")
        case .paused: return Color(hex: "F59E0B")
        }
    }

    // MARK: - Waveform View
    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<50, id: \.self) { index in
                let level = index < viewModel.audioLevels.count ? viewModel.audioLevels[index] : 0.05
                RoundedRectangle(cornerRadius: 2)
                    .fill(ThemeColors.waveformGradient)
                    .frame(width: 4, height: max(4, level * 80))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }

    // MARK: - State Label
    private var stateLabel: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Text("Tap record to begin")
                    .foregroundStyle(.white.opacity(0.35))
            case .recording:
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "EF4444"))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color(hex: "EF4444").opacity(0.6), radius: 4)
                    Text("Recording in progress...")
                        .foregroundStyle(.white.opacity(0.5))
                }
            case .paused:
                HStack(spacing: 8) {
                    Image(systemName: "pause.fill")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: "F59E0B"))
                    Text("Recording paused")
                        .foregroundStyle(Color(hex: "F59E0B").opacity(0.7))
                }
            }
        }
        .font(.subheadline)
    }

    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 40) {
            switch viewModel.state {
            case .idle:
                Button { viewModel.startRecording() } label: {
                    ZStack {
                        Circle()
                            .fill(ThemeColors.recordGradient)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: "EF4444").opacity(0.5), radius: 20)

                        Image(systemName: "mic.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                }

            case .recording:
                Button { viewModel.pauseRecording() } label: {
                    controlCircle(icon: "pause.fill", gradient: LinearGradient(colors: [Color(hex: "F59E0B"), Color(hex: "F97316")], startPoint: .topLeading, endPoint: .bottomTrailing), size: 60)
                }

                Button { viewModel.stopRecording() } label: {
                    controlCircle(icon: "stop.fill", gradient: ThemeColors.recordGradient, size: 80)
                }

            case .paused:
                Button { viewModel.resumeRecording() } label: {
                    controlCircle(icon: "play.fill", gradient: ThemeColors.successGradient, size: 60)
                }

                Button { viewModel.stopRecording() } label: {
                    controlCircle(icon: "stop.fill", gradient: ThemeColors.recordGradient, size: 80)
                }
            }
        }
    }

    private func controlCircle(icon: String, gradient: LinearGradient, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(gradient)
                .frame(width: size, height: size)
                .shadow(color: .white.opacity(0.1), radius: 10)

            Image(systemName: icon)
                .font(size > 70 ? .title : .title2)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    RecordView(meetingViewModel: MeetingViewModel())
        .environmentObject(ThemeManager.shared)
}
