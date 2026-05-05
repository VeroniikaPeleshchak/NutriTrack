import Foundation

class TrackingRepository {
    static let shared = TrackingRepository()
    private init() {}
    
    // MARK: - 1. Щоденник харчування (Diary)
    
    func getDiaryEntries(userId: Int) async throws -> [DiaryEntryDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/diary_entries?userId=\(userId)")
    }
    
    func getOrCreateDiaryEntry(userId: Int, date: Date, mealType: String) async throws -> DiaryEntryDTO {
        let request = DiaryEntryDTO(id: nil, userId: userId, date: date, mealType: mealType)
        return try await NetworkManager.shared.sendData(to: "/api/diary_entries/find-or-create", method: "POST", data: request)
    }
    
    // MARK: - 1.1 Спожиті продукти (Consumed Products)
    
    func getConsumedProducts(diaryEntryId: Int) async throws -> [ConsumedProductDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/consumed_products?diaryEntryId=\(diaryEntryId)")
    }
    
    func saveConsumedProduct(_ consumed: ConsumedProductDTO) async throws {
        if SyncService.shared.isOnline {
            _ = try await NetworkManager.shared.sendData(to: "/api/consumed_products", method: "POST", data: consumed) as ConsumedProductDTO
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/consumed_products", method: "POST", dto: consumed)
        }
    }
    
    func updateConsumedProduct(_ consumed: ConsumedProductDTO) async throws -> ConsumedProductDTO {
        guard let id = consumed.id else { throw NetworkManager.NetworkError.invalidURL }
        
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/consumed_products/\(id)", method: "PUT", data: consumed)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/consumed_products/\(id)", method: "PUT", dto: consumed)
            return consumed
        }
    }
    
    func deleteConsumedProduct(id: Int) async throws {
        if SyncService.shared.isOnline {
            try await NetworkManager.shared.sendRequest(to: "/api/consumed_products/\(id)", method: "DELETE")
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/consumed_products/\(id)", method: "DELETE")
        }
    }
    
    // MARK: - 2. Гідратація (Water Logs)
    
    func getWaterLogs(userId: Int) async throws -> [WaterLogDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/water?userId=\(userId)")
    }
    
    func saveWaterLog(_ log: WaterLogDTO) async throws {
        if SyncService.shared.isOnline {
            _ = try await NetworkManager.shared.sendData(to: "/api/water", method: "POST", data: log) as WaterLogDTO
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/water", method: "POST", dto: log)
        }
    }
    
    func updateWaterLog(_ log: WaterLogDTO) async throws -> WaterLogDTO {
        guard let id = log.id else { throw NetworkManager.NetworkError.invalidURL }
        
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/water/\(id)", method: "PUT", data: log)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/water/\(id)", method: "PUT", dto: log)
            return log
        }
    }
    
    func deleteWaterLog(id: Int) async throws {
        if SyncService.shared.isOnline {
            try await NetworkManager.shared.sendRequest(to: "/api/water/\(id)", method: "DELETE")
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/water/\(id)", method: "DELETE")
        }
    }
    
    // MARK: - 3. Виміри тіла (Measurements)
    
    func getMeasurementLogs(userId: Int) async throws -> [MeasurementLogDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/measurements?userId=\(userId)")
    }
    
    func saveMeasurementLog(_ log: MeasurementLogDTO) async throws {
        if SyncService.shared.isOnline {
            _ = try await NetworkManager.shared.sendData(to: "/api/measurements", method: "POST", data: log) as MeasurementLogDTO
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/measurements", method: "POST", dto: log)
        }
    }
    
    func updateMeasurementLog(_ log: MeasurementLogDTO) async throws -> MeasurementLogDTO {
        guard let id = log.id else { throw NetworkManager.NetworkError.invalidURL }
        
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/measurements/\(id)", method: "PUT", data: log)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/measurements/\(id)", method: "PUT", dto: log)
            return log
        }
    }
    
    func deleteMeasurementLog(id: Int) async throws {
        if SyncService.shared.isOnline {
            try await NetworkManager.shared.sendRequest(to: "/api/measurements/\(id)", method: "DELETE")
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/measurements/\(id)", method: "DELETE")
        }
    }
    
    // MARK: - 4. Активність (Activity/Steps)
    
    func getActivityLogs(userId: Int) async throws -> [ActivityLogDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/activity?userId=\(userId)")
    }
    
    func saveActivityLog(_ log: ActivityLogDTO) async throws {
        if SyncService.shared.isOnline {
            _ = try await NetworkManager.shared.sendData(to: "/api/activity", method: "POST", data: log) as ActivityLogDTO
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/activity", method: "POST", dto: log)
        }
    }
    
    func updateActivityLog(_ log: ActivityLogDTO) async throws -> ActivityLogDTO {
        guard let id = log.id else { throw NetworkManager.NetworkError.invalidURL }
        
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/activity/\(id)", method: "PUT", data: log)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/activity/\(id)", method: "PUT", dto: log)
            return log
        }
    }
    
    func deleteActivityLog(id: Int) async throws {
        if SyncService.shared.isOnline {
            try await NetworkManager.shared.sendRequest(to: "/api/activity/\(id)", method: "DELETE")
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/activity/\(id)", method: "DELETE")
        }
    }
    
    // MARK: - 5. Профіль користувача

    func getProfile(userId: Int) async throws -> [UserProfileDTO] {
        return try await NetworkManager.shared.fetchData(from: "/api/profiles?userId=\(userId)")
    }
    
    func saveProfile(_ profile: UserProfileDTO) async throws -> UserProfileDTO {
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/profiles", method: "POST", data: profile)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/profiles", method: "POST", dto: profile)
            return profile
        }
    }
    
    func updateProfile(_ profile: UserProfileDTO) async throws -> UserProfileDTO {
        guard let id = profile.id else { throw NetworkManager.NetworkError.invalidURL }
        
        if SyncService.shared.isOnline {
            return try await NetworkManager.shared.sendData(to: "/api/profiles/\(id)", method: "PUT", data: profile)
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/profiles/\(id)", method: "PUT", dto: profile)
            return profile
        }
    }
    
    func deleteProfile(id: Int) async throws {
        if SyncService.shared.isOnline {
            try await NetworkManager.shared.sendRequest(to: "/api/profiles/\(id)", method: "DELETE")
        } else {
            SyncService.shared.queueOfflineRequest(endpoint: "/api/profiles/\(id)", method: "DELETE")
        }
    }
}
