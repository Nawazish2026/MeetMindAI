import Foundation
import AVFoundation
import Combine

// MARK: - Audio Recorder Service
/// Wraps AVAudioRecorder to provide meeting recording functionality.
/// Publishes current time and audio power levels for UI visualization.
class AudioRecorderService: NSObject, ObservableObject {

    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var currentTime: TimeInterval = 0
    @Published var audioLevels: [CGFloat] = []

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?
    private(set) var audioFileURL: URL?

    // MARK: - Audio Session Setup
    /// Configures the shared audio session for recording.
    private func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
    }

    // MARK: - Generate File URL
    /// Creates a unique file URL in the documents directory for the recording.
    private func generateFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "meeting_\(UUID().uuidString).m4a"
        return documentsPath.appendingPathComponent(fileName)
    }

    // MARK: - Start Recording
    /// Begins audio recording to a new file.
    func startRecording() {
        do {
            try setupAudioSession()

            let url = generateFileURL()
            audioFileURL = url

            // Recording settings: AAC format, 44.1kHz, mono
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
            isPaused = false
            currentTime = 0

            // Start timer for elapsed time
            startTimers()

        } catch {
            print("❌ Recording failed to start: \(error.localizedDescription)")
        }
    }

    // MARK: - Pause Recording
    /// Pauses the current recording.
    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        stopTimers()
    }

    // MARK: - Resume Recording
    /// Resumes a paused recording.
    func resumeRecording() {
        audioRecorder?.record()
        isPaused = false
        startTimers()
    }

    // MARK: - Stop Recording
    /// Stops recording and returns the file URL.
    @discardableResult
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        stopTimers()

        isRecording = false
        isPaused = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)

        return audioFileURL
    }

    // MARK: - Timer Management
    private func startTimers() {
        // Elapsed time timer — fires every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime += 1
        }

        // Audio level timer — fires frequently for smooth waveform
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.audioRecorder?.updateMeters()
            let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            // Normalize power from dB range [-160, 0] to [0, 1]
            let normalizedPower = max(0, CGFloat(power + 160) / 160)
            DispatchQueue.main.async {
                self.audioLevels.append(normalizedPower)
                // Keep the last 50 samples for the waveform
                if self.audioLevels.count > 50 {
                    self.audioLevels.removeFirst()
                }
            }
        }
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    // MARK: - Formatted Time
    /// Returns a formatted string of current recording time (MM:SS).
    var formattedTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("⚠️ Recording finished unsuccessfully")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("❌ Encoding error: \(error.localizedDescription)")
        }
    }
}
