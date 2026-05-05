import Foundation

class WaterTrackerService {
    static let shared = WaterTrackerService()
    private init() {}
    
    func getTodayWaterTotal() async throws -> Int {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований"])
        }
        
        let allLogs = try await TrackingRepository.shared.getWaterLogs(userId: userId)
        let calendar = Calendar.current
        
        let todayLogs = allLogs.filter { calendar.isDateInToday($0.date) }
        
        return todayLogs.reduce(0) { $0 + $1.amountMl }
    }
    
    func addWater(amountMl: Int) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований"])
        }

        let newLog = WaterLogDTO(id: nil, userId: userId, date: Date(), amountMl: amountMl)
        
        try await TrackingRepository.shared.saveWaterLog(newLog)
    }
    
    func deleteWater(logId: Int) async throws {
        guard AuthManager.shared.isAuthenticated else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований"])
        }

        try await TrackingRepository.shared.deleteWaterLog(id: logId)
        print("Запис про воду (ID: \(logId)) успішно видалено.")
    }
}
