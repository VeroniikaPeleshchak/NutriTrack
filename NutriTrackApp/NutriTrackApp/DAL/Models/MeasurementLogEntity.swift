import Foundation

struct MeasurementLogEntity: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let weightKg: Double
    let waistCm: Double?
    let chestCm: Double?
    let hipsCm: Double?
}
