import Foundation
import Network
import CoreData

class SyncService {
    static let shared = SyncService()
    
    private let monitor = NWPathMonitor()
    private(set) var isOnline = true
    private var isSyncing = false
    
    private init() {}
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let currentStatus = path.status == .satisfied
            self?.isOnline = currentStatus
            
            if currentStatus {
                Task {
                    await self?.syncPendingData()
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    // MARK: - 1. Черга для POST та PUT
    func queueOfflineRequest<T: Codable>(endpoint: String, method: String, dto: T) {
        let context = CoreDataManager.shared.viewContext
        let request = NSEntityDescription.insertNewObject(forEntityName: "OfflineRequest", into: context)
        
        request.setValue(UUID(), forKey: "id")
        request.setValue(endpoint, forKey: "endpoint")
        request.setValue(method, forKey: "method")
        request.setValue(Date(), forKey: "timestamp")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let encodedData = try? encoder.encode(dto) {
            request.setValue(encodedData, forKey: "payload")
        }
        
        CoreDataManager.shared.saveContext()
        print("Немає мережі. Запит [\(method)] до \(endpoint) збережено офлайн.")
    }
    
    // MARK: - 2. ДОДАНО: Черга для DELETE
    func queueOfflineRequest(endpoint: String, method: String) {
        let context = CoreDataManager.shared.viewContext
        let request = NSEntityDescription.insertNewObject(forEntityName: "OfflineRequest", into: context)
        
        request.setValue(UUID(), forKey: "id")
        request.setValue(endpoint, forKey: "endpoint")
        request.setValue(method, forKey: "method")
        request.setValue(Date(), forKey: "timestamp")
        
        CoreDataManager.shared.saveContext()
        print("Немає мережі. Запит [\(method)] до \(endpoint) збережено офлайн.")
    }
    
    // MARK: - 3. Синхронізація
    private func syncPendingData() async {
        guard isOnline, !isSyncing else { return }
        isSyncing = true
        
        let context = CoreDataManager.shared.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "OfflineRequest")
        
        let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let pendingRequests = try context.fetch(fetchRequest)
            
            for request in pendingRequests {
                guard let endpoint = request.value(forKey: "endpoint") as? String,
                      let method = request.value(forKey: "method") as? String else {
                    continue
                }
                
                let payloadData = request.value(forKey: "payload") as? Data
                
                do {
                    if let data = payloadData {
                        try await NetworkManager.shared.sendRawData(to: endpoint, method: method, data: data)
                    } else {
                        try await NetworkManager.shared.sendRequest(to: endpoint, method: method)
                    }
                    
                    context.delete(request)
                    CoreDataManager.shared.saveContext()
                    print("Успішно синхронізовано офлайн-запит: [\(method)] \(endpoint)")
                    
                } catch {
                    print("Сервер відхилив синхронізацію для \(endpoint): \(error)")
                    break 
                }
            }
        } catch {
            print("Помилка отримання офлайн-черги: \(error.localizedDescription)")
        }
        
        isSyncing = false
    }
}
