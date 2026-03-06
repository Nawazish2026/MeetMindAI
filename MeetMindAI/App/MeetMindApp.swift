import SwiftUI

// MARK: - MeetMind AI App
/// Main entry point for the MeetMind AI application.
@main
struct MeetMindApp: App {

    // Inject CoreData service as a shared instance
    let coreDataService = CoreDataService.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, coreDataService.viewContext)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
