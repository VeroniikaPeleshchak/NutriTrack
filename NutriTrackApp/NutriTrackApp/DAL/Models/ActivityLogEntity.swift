import Foundation

struct ActivityLogEntity: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let steps: Int
    let burnedCalories: Double
}
