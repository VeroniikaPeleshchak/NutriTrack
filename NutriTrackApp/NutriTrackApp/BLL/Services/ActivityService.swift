import Foundation

class ActivityService {
    static let shared = ActivityService()
    private init() {}
    
    func getTodayActivity() async throws -> ActivityLogDTO? {
        guard let userId = AuthManager.shared.currentUserId else { return nil }
        
        if AuthManager.shared.currentUserProfile?.isAppleHealthSyncEnabled == true {
            try? await syncWithHealthKit(for: Date())
        }
        
        let logs = try await TrackingRepository.shared.getActivityLogs(userId: userId)
        let calendar = Calendar.current
        return logs.first(where: { calendar.isDateInToday($0.date) })
    }
    
    func syncWithHealthKit(for date: Date = Date()) async throws {
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        let hasAccess = try await HealthKitManager.shared.requestAuthorization()
        guard hasAccess else { return }
        
        let steps = try await HealthKitManager.shared.fetchSteps(for: date)
        let energy = try await HealthKitManager.shared.fetchActiveEnergy(for: date)
        
        let logs = try await TrackingRepository.shared.getActivityLogs(userId: userId)
        let calendar = Calendar.current
        
        let targetLog = logs.first(where: { calendar.isDate($0.date, inSameDayAs: date) })
        
        if let existing = targetLog {
            let updatedLog = ActivityLogDTO(
                id: existing.id,
                userId: userId,
                date: existing.date,
                steps: Int(steps),
                burnedCalories: energy
            )
            _ = try await TrackingRepository.shared.updateActivityLog(updatedLog)
        } else {
            let newLog = ActivityLogDTO(
                id: nil,
                userId: userId,
                date: date,
                steps: Int(steps),
                burnedCalories: energy
            )
            try await TrackingRepository.shared.saveActivityLog(newLog)
        }
    }
}
