import Foundation

class BackupService {
    static let shared = BackupService()
    private init() {}
    
    private var iCloudContainerURL: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    func createBackup() async throws {
        guard let folderURL = iCloudContainerURL else {
            throw NSError(domain: "Backup", code: 403, userInfo: [NSLocalizedDescriptionKey: "iCloud Drive недоступний."])
        }
        
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "Backup", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований."])
        }
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        }

        let currentProfile = AuthManager.shared.currentUserProfile
        
        let waterLogs = (try? await TrackingRepository.shared.getWaterLogs(userId: userId)) ?? []
        let measurementLogs = (try? await TrackingRepository.shared.getMeasurementLogs(userId: userId)) ?? []
        let activityLogs = (try? await TrackingRepository.shared.getActivityLogs(userId: userId)) ?? []
        let diaryEntries = (try? await TrackingRepository.shared.getDiaryEntries(userId: userId)) ?? []
        
        var consumedProducts: [ConsumedProductDTO] = []
        for entry in diaryEntries {
            if let entryId = entry.id,
               let productsHere = try? await TrackingRepository.shared.getConsumedProducts(diaryEntryId: entryId) {
                consumedProducts.append(contentsOf: productsHere)
            }
        }
        
        let customProducts = (try? await CatalogRepository.shared.getProducts()) ?? []
        
        let backupData = BackupDTO(
            backupDate: Date(),
            profile: currentProfile,
            waterLogs: waterLogs,
            measurementLogs: measurementLogs,
            activityLogs: activityLogs,
            diaryEntries: diaryEntries,
            consumedProducts: consumedProducts,
            customProducts: customProducts
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backupData)
        
        let backupFileURL = folderURL.appendingPathComponent("NutriTrack_Backup.json")
        try data.write(to: backupFileURL, options: Data.WritingOptions.atomic)
    }
    
    func restoreFromBackup() async throws {
        guard let fileURL = iCloudContainerURL?.appendingPathComponent("NutriTrack_Backup.json") else {
            throw NSError(domain: "Backup", code: 404, userInfo: [NSLocalizedDescriptionKey: "Файл резервної копії не знайдено."])
        }
        
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "Backup", code: 401, userInfo: [NSLocalizedDescriptionKey: "Спочатку авторизуйтесь для відновлення даних."])
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backupData = try decoder.decode(BackupDTO.self, from: data)
        
        if let restoredProfile = backupData.profile {
            AuthManager.shared.currentUserProfile = restoredProfile
            _ = try? await TrackingRepository.shared.updateProfile(restoredProfile)
        }
        
        for waterLog in backupData.waterLogs {
            let newLog = WaterLogDTO(id: nil, userId: userId, date: waterLog.date, amountMl: waterLog.amountMl)
            try? await TrackingRepository.shared.saveWaterLog(newLog)
        }
        
        for mLog in backupData.measurementLogs {
            let newLog = MeasurementLogDTO(id: nil, userId: userId, date: mLog.date, weightKg: mLog.weightKg, waistCm: mLog.waistCm, chestCm: mLog.chestCm, hipsCm: mLog.hipsCm)
            try? await TrackingRepository.shared.saveMeasurementLog(newLog)
        }
        
        for activity in backupData.activityLogs {
            let newLog = ActivityLogDTO(
                id: nil,
                userId: userId,
                date: activity.date,
                steps: activity.steps,
                burnedCalories: activity.burnedCalories
            )
            try? await TrackingRepository.shared.saveActivityLog(newLog)
        }
        
        for entry in backupData.diaryEntries {
            guard let oldEntryId = entry.id else { continue }
            
            if let savedEntry = try? await TrackingRepository.shared.getOrCreateDiaryEntry(userId: userId, date: entry.date, mealType: entry.mealType),
               let newEntryId = savedEntry.id {
                
                let productsForThisEntry = backupData.consumedProducts.filter { $0.diaryEntryId == oldEntryId }
                
                for consumed in productsForThisEntry {
                    let newConsumed = ConsumedProductDTO(id: nil, diaryEntryId: newEntryId, productId: consumed.productId, amount: consumed.amount, measurementUnit: consumed.measurementUnit)
                    try? await TrackingRepository.shared.saveConsumedProduct(newConsumed)
                }
            }
        }
        
        print("Дані успішно відновлено та завантажено на сервер")
    }
}
