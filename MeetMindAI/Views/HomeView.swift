import SwiftUI

// MARK: - Home View
/// Main screen displaying the list of meetings, search, theme toggle, and a record button.
struct HomeView: View {

    @StateObject private var viewModel = MeetingViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var showRecordView = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Adaptive background
                backgroundGradient
                    .ignoresSafeArea()

                if viewModel.showEmptyState {
                    emptyStateView
                } else {
                    meetingListView
                }

                // Floating record button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        recordButton
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("MeetMind AI")
            .searchable(text: $viewModel.searchText, prompt: "Search meetings...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: themeManager.currentTheme.icon)
                            .font(.title3)
                            .foregroundStyle(ThemeColors.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheet(themeManager: themeManager)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showRecordView) {
                RecordView(meetingViewModel: viewModel)
                    .environmentObject(themeManager)
            }
            .onAppear {
                viewModel.loadMeetings()
            }
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [Color(hex: "0F0F1A"), Color(hex: "1A1A2E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [Color(hex: "F8FAFC"), Color(hex: "EEF2FF")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    // MARK: - Meeting List
    private var meetingListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.groupedMeetings, id: \.0) { section, meetings in
                    // Section Header
                    HStack {
                        Text(section)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    ForEach(meetings) { meeting in
                        NavigationLink(value: meeting) {
                            MeetingCardView(meeting: meeting)
                                .environment(\.colorScheme, colorScheme)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.deleteMeeting(meeting)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .navigationDestination(for: Meeting.self) { meeting in
            MeetingDetailView(meeting: meeting, meetingViewModel: viewModel)
                .environmentObject(themeManager)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.05)
                            : Color(hex: "6366F1").opacity(0.08)
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(ThemeColors.primaryGradient)
            }

            Text("No Meetings Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Tap the record button to start\ncapturing your first meeting.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Record Button (FAB)
    private var recordButton: some View {
        Button {
            showRecordView = true
        } label: {
            ZStack {
                Circle()
                    .fill(ThemeColors.recordGradient)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 12, x: 0, y: 6)

                Image(systemName: "mic.fill")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Settings Sheet
/// Sheet showing theme toggle and app info.
struct SettingsSheet: View {

    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            List {
                // Theme selection
                Section {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                themeManager.setTheme(theme)
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(themeManager.currentTheme == theme
                                              ? Color(hex: "6366F1").opacity(0.15)
                                              : Color.secondary.opacity(0.1))
                                        .frame(width: 36, height: 36)

                                    Image(systemName: theme.icon)
                                        .font(.body)
                                        .foregroundStyle(
                                            themeManager.currentTheme == theme
                                                ? Color(hex: "6366F1")
                                                : .secondary
                                        )
                                }

                                Text(theme.rawValue)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if themeManager.currentTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color(hex: "6366F1"))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("Appearance", systemImage: "paintbrush.fill")
                }

                // App info
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Built with")
                        Spacer()
                        Text("SwiftUI + OpenAI")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("About", systemImage: "info.circle.fill")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Meeting Card View
struct MeetingCardView: View {
    let meeting: Meeting
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // Leading icon
            ZStack {
                Circle()
                    .fill(
                        colorScheme == .dark
                            ? Color(hex: "6366F1").opacity(0.15)
                            : Color(hex: "6366F1").opacity(0.1)
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundStyle(ThemeColors.primaryGradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(meeting.formattedDuration, systemImage: "clock")
                    Text("•")
                    Text(meeting.formattedDate)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Summary indicator
            if !meeting.summary.isEmpty {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color(hex: "F59E0B"))
                    .font(.caption)
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark
                      ? Color(hex: "1E1E2E")
                      : Color.white
                )
                .shadow(
                    color: colorScheme == .dark
                        ? Color.clear
                        : Color.black.opacity(0.04),
                    radius: 8, x: 0, y: 2
                )
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(ThemeManager.shared)
}
