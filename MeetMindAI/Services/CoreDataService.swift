import Foundation
import CoreData

// MARK: - CoreData Service
/// Handles all CoreData operations: create, read, update, delete, and search.
class CoreDataService: ObservableObject {

    // MARK: - Shared Instance
    static let shared = CoreDataService()

    // MARK: - Persistent Container
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MeetMindAI")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ CoreData failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// The main view context.
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Save Context
    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("❌ CoreData save error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Create Meeting
    /// Saves a Meeting struct into CoreData.
    @discardableResult
    func saveMeeting(_ meeting: Meeting) -> MeetingEntity? {
        let entity = MeetingEntity(context: viewContext)
        entity.id = meeting.id
        entity.title = meeting.title
        entity.date = meeting.date
        entity.duration = meeting.duration
        entity.transcript = meeting.transcript
        entity.summary = meeting.summary
        entity.actionItems = meeting.actionItems
        entity.audioFilePath = meeting.audioFilePath
        save()
        return entity
    }

    // MARK: - Fetch All Meetings
    /// Returns all meetings sorted by date (newest first).
    func fetchMeetings() -> [Meeting] {
        let request: NSFetchRequest<MeetingEntity> = MeetingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MeetingEntity.date, ascending: false)]

        do {
            let entities = try viewContext.fetch(request)
            return entities.map { mapToMeeting($0) }
        } catch {
            print("❌ Fetch error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Search Meetings
    /// Searches meetings by keyword across title, transcript, summary, and action items.
    func searchMeetings(query: String) -> [Meeting] {
        let request: NSFetchRequest<MeetingEntity> = MeetingEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MeetingEntity.date, ascending: false)]
        request.predicate = NSPredicate(
            format: "title CONTAINS[cd] %@ OR transcript CONTAINS[cd] %@ OR summary CONTAINS[cd] %@ OR actionItems CONTAINS[cd] %@",
            query, query, query, query
        )

        do {
            let entities = try viewContext.fetch(request)
            return entities.map { mapToMeeting($0) }
        } catch {
            print("❌ Search error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Delete Meeting
    /// Deletes a meeting by ID.
    func deleteMeeting(id: UUID) {
        let request: NSFetchRequest<MeetingEntity> = MeetingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let entities = try viewContext.fetch(request)
            for entity in entities {
                viewContext.delete(entity)
            }
            save()
        } catch {
            print("❌ Delete error: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Meeting
    /// Updates an existing meeting's summary and action items.
    func updateMeeting(_ meeting: Meeting) {
        let request: NSFetchRequest<MeetingEntity> = MeetingEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", meeting.id as CVarArg)

        do {
            if let entity = try viewContext.fetch(request).first {
                entity.title = meeting.title
                entity.transcript = meeting.transcript
                entity.summary = meeting.summary
                entity.actionItems = meeting.actionItems
                entity.duration = meeting.duration
                save()
            }
        } catch {
            print("❌ Update error: \(error.localizedDescription)")
        }
    }

    // MARK: - Mapping
    /// Maps a CoreData entity to a Meeting value type.
    private func mapToMeeting(_ entity: MeetingEntity) -> Meeting {
        Meeting(
            id: entity.id ?? UUID(),
            title: entity.title ?? "Untitled",
            date: entity.date ?? Date(),
            duration: entity.duration,
            transcript: entity.transcript ?? "",
            summary: entity.summary ?? "",
            actionItems: entity.actionItems ?? "",
            audioFilePath: entity.audioFilePath ?? ""
        )
    }
}
