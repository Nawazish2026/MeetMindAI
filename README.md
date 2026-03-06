# 🧠 MeetMind AI

**AI-powered meeting recorder** that converts speech → text → AI summary → action items.

Built with **Swift + SwiftUI** using clean **MVVM architecture** and **Google Gemini AI**.

---

## 📱 Screenshots

### Home Screen (Dark & Light Mode)

| Dark Mode | Light Mode |
|---|---|
| <img src="Screenshots/home_dark.png" width="300"> | <img src="Screenshots/home_light.png" width="300"> |

### Recording Screen

<p align="center">
  <img src="Screenshots/recording.png" width="320">
</p>

### AI Summary

<p align="center">
  <img src="Screenshots/summary.png" width="320">
</p>

### Meeting Detail

<p align="center">
  <img src="Screenshots/detail.png" width="320">
</p>

### Settings (Theme Toggle)

<p align="center">
  <img src="Screenshots/settings.png" width="320">
</p>

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎤 **Record** | Record meetings with real-time waveform visualization |
| 📝 **Transcribe** | Speech-to-text using Apple's Speech framework |
| 🤖 **AI Summary** | Gemini AI-powered summaries, key points, action items |
| 📂 **History** | CoreData-backed meeting storage with smart search |
| 📤 **Export** | PDF export and system share sheet |
| 🔊 **Playback** | Built-in audio player on meeting detail |
| 🌙 **Themes** | System / Light / Dark mode toggle |

---

## 🏗️ Architecture

```
MVVM (Model – View – ViewModel)

View → ViewModel → Service → Framework/API
```

### Project Structure

```
MeetMindAI/
├── App/                  → MeetMindApp.swift
├── Models/               → Meeting.swift
├── ViewModels/           → MeetingViewModel, RecorderViewModel, AIViewModel
├── Views/                → HomeView, RecordView, TranscriptView, SummaryView, MeetingDetailView
├── Services/             → CoreData, AudioRecorder, SpeechRecognition, Gemini AI, Secrets
├── Utilities/            → PDFExporter, ThemeManager
└── Resources/            → Assets.xcassets, MeetMindAI.xcdatamodeld
```

---

## 🛠 Tech Stack

| Component | Technology |
|---|---|
| UI | SwiftUI |
| Architecture | MVVM |
| Audio | AVFoundation |
| Speech-to-Text | Speech Framework |
| AI | Google Gemini API (gemini-2.0-flash) |
| Storage | CoreData |
| Export | PDFKit |
| Networking | URLSession |

---

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 17+ deployment target
- Google Gemini API key

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Nawazish2026/MeetMindAI.git
   ```

2. Create a `Secrets.swift` file in `MeetMindAI/Services/`:
   ```swift
   import Foundation

   enum Secrets {
       static let geminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
   }
   ```
   > ⚠️ This file is **gitignored** to protect your API key.

3. Open `MeetMindAI.xcodeproj` in Xcode

4. Select a simulator or device → Build & Run (⌘R)

> **Note:** Microphone recording and speech recognition require a **physical device** for full functionality.

---

## 📱 Screens

| Screen | Purpose |
|---|---|
| **Home** | Meeting list, search, record button, theme toggle |
| **Record** | Timer, waveform, pause/stop controls (immersive dark) |
| **Transcript** | Live transcription display with word count |
| **AI Summary** | Summary, key points, action items, decisions, insights |
| **Meeting Detail** | Audio playback, tabbed content, PDF export |
| **Settings** | System / Light / Dark theme selector |

---

## 🔐 Security

- API keys are stored in `Secrets.swift` which is **gitignored**
- No third-party dependencies — 100% Apple frameworks + Google Gemini API
- All data stored locally via CoreData

---

## 📄 License

MIT License
