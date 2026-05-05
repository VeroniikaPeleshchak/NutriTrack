import Foundation

class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    // MARK: - 1. Онбординг (Створення профілю)
    func setupProfile(name: String, gender: String, dateOfBirth: Date, height: Double, currentWeight: Double, goalWeight: Double, activityLevelStr: String) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований"])
        }
        
        let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 20
        let goal: UserGoal = (goalWeight < currentWeight) ? .loseWeight : (goalWeight > currentWeight ? .gainWeight : .maintain)
        let activityEnum = mapActivityLevel(from: activityLevelStr)
        
        let norms = NutriCalculator.shared.calculateNorms(
            weightKg: currentWeight,
            heightCm: height,
            age: age,
            isMale: gender == "Чоловік",
            activity: activityEnum,
            goal: goal
        )
        
        let newProfile = UserProfileDTO(
            id: nil, userId: userId, gender: gender, dateOfBirth: dateOfBirth, height: height, currentWeight: currentWeight,
            goalWeight: goalWeight, activityLevel: activityLevelStr, dailyCalorieGoal: norms.calories, dailyProteinGoal: norms.proteins,
            dailyFatGoal: norms.fats, dailyCarbGoal: norms.carbs, isAppleHealthSyncEnabled: false, name: name
        )
        
        let savedProfile = try await TrackingRepository.shared.saveProfile(newProfile)
        AuthManager.shared.currentUserProfile = savedProfile
        
        let firstLog = MeasurementLogDTO(
            id: nil, userId: userId, date: Date(), weightKg: currentWeight, waistCm: nil, chestCm: nil, hipsCm: nil
        )
        try await TrackingRepository.shared.saveMeasurementLog(firstLog)
    }
    
    // MARK: - 2. Оновлення вимірів
    func updateMeasurements(weight: Double? = nil, waist: Double? = nil, chest: Double? = nil, hips: Double? = nil) async throws {
        guard var profile = AuthManager.shared.currentUserProfile else { return }
        
        var needsProfileUpdate = false
        let savedWeight = weight ?? profile.currentWeight
        
        if let newWeight = weight, newWeight != profile.currentWeight {
            profile.currentWeight = newWeight
            needsProfileUpdate = true
        }
        
        if needsProfileUpdate {
            let age = Calendar.current.dateComponents([.year], from: profile.dateOfBirth, to: Date()).year ?? 20
            let goal: UserGoal = (profile.goalWeight < profile.currentWeight) ? .loseWeight : (profile.goalWeight > profile.currentWeight ? .gainWeight : .maintain)
            let activityEnum = mapActivityLevel(from: profile.activityLevel)
            
            let norms = NutriCalculator.shared.calculateNorms(
                weightKg: profile.currentWeight, heightCm: profile.height, age: age,
                isMale: profile.gender == "Чоловік", activity: activityEnum, goal: goal
            )
            
            let updatedProfile = UserProfileDTO(
                id: profile.id, userId: profile.userId, gender: profile.gender, dateOfBirth: profile.dateOfBirth,
                height: profile.height, currentWeight: profile.currentWeight, goalWeight: profile.goalWeight,
                activityLevel: profile.activityLevel, dailyCalorieGoal: norms.calories, dailyProteinGoal: norms.proteins,
                dailyFatGoal: norms.fats, dailyCarbGoal: norms.carbs, isAppleHealthSyncEnabled: profile.isAppleHealthSyncEnabled,
                name: profile.name
            )
            
            let savedProfile = try await TrackingRepository.shared.updateProfile(updatedProfile)
            AuthManager.shared.currentUserProfile = savedProfile
        }
        
        let newLog = MeasurementLogDTO(
            id: nil, userId: profile.userId, date: Date(), weightKg: savedWeight, waistCm: waist, chestCm: chest, hipsCm: hips
        )
        try await TrackingRepository.shared.saveMeasurementLog(newLog)
    }
    
    // MARK: - 3. Apple Health та Видалення
    func toggleAppleHealthSync(isEnabled: Bool) async throws {
        guard var profile = AuthManager.shared.currentUserProfile else { return }
        
        if isEnabled {
            let hasAccess = try await HealthKitManager.shared.requestAuthorization()
            guard hasAccess else { throw NSError(domain: "HealthKit", code: 403, userInfo: [NSLocalizedDescriptionKey: "Немає доступу до Apple Health."]) }
            
            try await ActivityService.shared.syncWithHealthKit()
        }
        
        let updatedProfile = UserProfileDTO(
            id: profile.id, userId: profile.userId, gender: profile.gender, dateOfBirth: profile.dateOfBirth,
            height: profile.height, currentWeight: profile.currentWeight, goalWeight: profile.goalWeight,
            activityLevel: profile.activityLevel, dailyCalorieGoal: profile.dailyCalorieGoal, dailyProteinGoal: profile.dailyProteinGoal,
            dailyFatGoal: profile.dailyFatGoal, dailyCarbGoal: profile.dailyCarbGoal, isAppleHealthSyncEnabled: isEnabled,
            name: profile.name
        )
        
        let savedProfile = try await TrackingRepository.shared.updateProfile(updatedProfile)
        AuthManager.shared.currentUserProfile = savedProfile
    }
    
    func deleteMeasurementLog(logId: Int) async throws {
        guard AuthManager.shared.isAuthenticated else { return }
        try await TrackingRepository.shared.deleteMeasurementLog(id: logId)
    }
    
    func deleteAccount() async throws {
        guard let userId = AuthManager.shared.currentUserId else { return }
        try await AuthRepository.shared.deleteAccount(userId: userId)
        await AuthService.shared.logout()
    }
    
    // MARK: - Отримання існуючого профілю
    func getProfile() async throws -> UserProfileDTO? {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований"])
        }
        
        if let profile = try await TrackingRepository.shared.getProfile(userId: userId).first {
            AuthManager.shared.currentUserProfile = profile
            return profile
        }
        
        return nil
    }
    
    // MARK: - Допоміжний метод (Мапер)
    private func mapActivityLevel(from string: String) -> ActivityLevel {
        switch string.lowercased() {
        case "Сидячий спосіб життя", "sedentary": return .sedentary
        case "Легка активність", "light": return .light
        case "Помірна активність", "moderate": return .moderate
        case "Висока активність", "active": return .active
        case "Дуже висока активність", "veryactive": return .veryActive
        default: return .moderate
        }
    }
}
