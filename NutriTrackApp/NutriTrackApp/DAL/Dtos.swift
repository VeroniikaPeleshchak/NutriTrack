import Foundation

// MARK: - User DTOs
struct UserDTO: Codable {
    let id: Int?
    let email: String
    let passwordHash: String
    let role: String
    let name: String
}

struct UserProfileDTO: Codable {
    let id: Int?
    let userId: Int
    let gender: String
    let dateOfBirth: Date
    var height: Double
    var currentWeight: Double
    var goalWeight: Double
    var activityLevel: String
    var dailyCalorieGoal: Double
    var dailyProteinGoal: Double
    var dailyFatGoal: Double
    var dailyCarbGoal: Double
    var isAppleHealthSyncEnabled: Bool
    var name: String
}

// MARK: - Product DTOs
struct ProductDTO: Codable {
    let id: Int?
    let name: String
    let calories: Double
    let proteins: Double
    let carbs: Double
    let fats: Double
    let barcode: String?
    let isApproved: Bool
    let createdByUserId: Int?
    var isRejected: Bool? = false
}

// MARK: - Diary DTOs
struct DiaryEntryDTO: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let mealType: String
}

struct ConsumedProductDTO: Codable {
    let id: Int?
    let diaryEntryId: Int
    let productId: Int
    let amount: Double
    let measurementUnit: String
}

// MARK: - Logs DTOs
struct WaterLogDTO: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let amountMl: Int
}

struct MeasurementLogDTO: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let weightKg: Double
    let waistCm: Double?
    let chestCm: Double?
    let hipsCm: Double?
}

struct ActivityLogDTO: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let steps: Int
    let burnedCalories: Double
}

// MARK: - Auth DTOs
struct AppleLoginRequestDTO: Codable {
    let identityToken: String
    let email: String?
    let name: String?
}

struct AuthResponseDTO: Codable {
    let token: String
    let user: UserDTO
}

struct LoginRequestDTO: Codable {
    let email: String
    let passwordHash: String
}

struct RegisterRequestDTO: Codable {
    let email: String
    let passwordHash: String
    let name: String
}

// MARK: - Admin DTOs
struct AdminStatsDTO: Codable {
    let activeUsers: Int
    let totalProducts: Int
    let pendingRequests: Int
}

// MARK: - Backup DTO
struct BackupDTO: Codable {
    let backupDate: Date
    let profile: UserProfileDTO?
    let waterLogs: [WaterLogDTO]
    let measurementLogs: [MeasurementLogDTO]
    let activityLogs: [ActivityLogDTO]
    let diaryEntries: [DiaryEntryDTO]
    let consumedProducts: [ConsumedProductDTO]
    let customProducts: [ProductDTO]
}
