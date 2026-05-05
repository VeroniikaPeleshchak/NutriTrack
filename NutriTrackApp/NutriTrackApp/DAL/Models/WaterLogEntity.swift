import Foundation

struct WaterLogEntity: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let amountMl: Int
}
