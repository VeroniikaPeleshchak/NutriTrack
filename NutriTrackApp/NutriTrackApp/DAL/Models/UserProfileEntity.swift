import Foundation

struct UserProfileEntity: Codable {
    let id: Int?
    let userId: Int
    let gender: String
    let dateOfBirth: Date
    let height: Double
    let currentWeight: Double
    let goalWeight: Double
    let activityLevel: String
    let dailyCalorieGoal: Double
    let dailyProteinGoal: Double
    let dailyFatGoal: Double
    let dailyCarbGoal: Double
    let isAppleHealthSyncEnabled: Bool
    let name: String
}
