import Foundation
import Combine

// MARK: - Recording State
enum RecordingState {
    case idle
    case recording
    case paused
}

// MARK: - Recorder ViewModel
/// Manages the recording flow: timer, waveform data, and transitions.
class RecorderViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var state: RecordingState = .idle
    @Published var currentTime: TimeInterval = 0
    @Published var audioLevels: [CGFloat] = []
    @Published var meetingTitle: String = ""
    @Published var recordingCompleted: Bool = false

    // MARK: - Services
    let audioService = AudioRecorderService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - File URL
    var audioFileURL: URL? {
        audioService.audioFileURL
    }

    // MARK: - Init
    init() {
        // Subscribe to audio service updates
        audioService.$currentTime
            .receive(on: RunLoop.main)
            .assign(to: &$currentTime)

        audioService.$audioLevels
            .receive(on: RunLoop.main)
            .assign(to: &$audioLevels)

        // Generate a default title with the current date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        meetingTitle = "Meeting \(formatter.string(from: Date()))"
    }

    // MARK: - Formatted Time
    var formattedTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Actions

    /// Starts a new recording.
    func startRecording() {
        audioService.startRecording()
        state = .recording
        recordingCompleted = false
    }

    /// Pauses the active recording.
    func pauseRecording() {
        audioService.pauseRecording()
        state = .paused
    }

    /// Resumes a paused recording.
    func resumeRecording() {
        audioService.resumeRecording()
        state = .recording
    }

    /// Stops the recording and signals completion.
    func stopRecording() {
        audioService.stopRecording()
        state = .idle
        recordingCompleted = true
    }

    /// Resets the recorder to the idle state.
    func reset() {
        state = .idle
        currentTime = 0
        audioLevels = []
        recordingCompleted = false
    }
}
