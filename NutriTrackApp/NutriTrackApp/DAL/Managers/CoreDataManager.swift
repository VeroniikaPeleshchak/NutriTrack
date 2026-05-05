import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "NutriTrackModel")
        
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Не вдалося завантажити Core Data: \(error.localizedDescription)")
            }
        }
        
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                print("Помилка збереження в Core Data: \(error.localizedDescription)")
            }
        }
    }
}
