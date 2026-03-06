import Foundation
import Combine

// MARK: - Meeting ViewModel
/// Manages the list of meetings, search, and CRUD operations for the Home screen.
class MeetingViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var meetings: [Meeting] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    private let coreDataService: CoreDataService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(coreDataService: CoreDataService = .shared) {
        self.coreDataService = coreDataService
        setupSearchSubscription()
        loadMeetings()
    }

    // MARK: - Search Subscription
    /// Debounces search input and fetches filtered results.
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.loadMeetings()
                } else {
                    self.searchMeetings(query: query)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Load Meetings
    /// Fetches all meetings from CoreData.
    func loadMeetings() {
        isLoading = true
        meetings = coreDataService.fetchMeetings()
        isLoading = false
    }

    // MARK: - Search
    /// Searches meetings with a keyword query.
    private func searchMeetings(query: String) {
        meetings = coreDataService.searchMeetings(query: query)
    }

    // MARK: - Save Meeting
    /// Saves a new meeting to CoreData and refreshes the list.
    func saveMeeting(_ meeting: Meeting) {
        coreDataService.saveMeeting(meeting)
        loadMeetings()
    }

    // MARK: - Delete Meeting
    /// Deletes a meeting by ID and refreshes the list.
    func deleteMeeting(_ meeting: Meeting) {
        // Delete the audio file if it exists
        if !meeting.audioFilePath.isEmpty {
            let url = URL(fileURLWithPath: meeting.audioFilePath)
            try? FileManager.default.removeItem(at: url)
        }
        coreDataService.deleteMeeting(id: meeting.id)
        loadMeetings()
    }

    // MARK: - Update Meeting
    /// Updates an existing meeting and refreshes the list.
    func updateMeeting(_ meeting: Meeting) {
        coreDataService.updateMeeting(meeting)
        loadMeetings()
    }

    // MARK: - Computed Properties

    /// True when there are no meetings and no active search.
    var showEmptyState: Bool {
        meetings.isEmpty && searchText.isEmpty
    }

    /// Meetings grouped by relative date for section headers.
    var groupedMeetings: [(String, [Meeting])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: meetings) { meeting -> String in
            if calendar.isDateInToday(meeting.date) {
                return "Today"
            } else if calendar.isDateInYesterday(meeting.date) {
                return "Yesterday"
            } else if calendar.isDate(meeting.date, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: meeting.date)
            }
        }
        // Sort groups: Today first, then Yesterday, then chronological
        let order = ["Today", "Yesterday", "This Week"]
        return grouped.sorted { a, b in
            let aIndex = order.firstIndex(of: a.key) ?? Int.max
            let bIndex = order.firstIndex(of: b.key) ?? Int.max
            return aIndex < bIndex
        }
    }
}
