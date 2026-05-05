import Foundation

struct ProductEntity: Codable {
    let id: Int?
    let name: String
    let calories: Double
    let proteins: Double
    let carbs: Double
    let fats: Double
    let barcode: String?
    let isApproved: Bool
    let createdByUserId: Int?
}
