import Foundation

struct ConsumedProductEntity: Codable {
    let id: Int?
    let diaryEntryId: Int
    let productId: Int
    let amount: Double
    let measurementUnit: String
}
