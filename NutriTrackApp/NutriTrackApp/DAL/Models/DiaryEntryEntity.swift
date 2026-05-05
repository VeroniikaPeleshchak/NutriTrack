import Foundation

struct DiaryEntryEntity: Codable {
    let id: Int?
    let userId: Int
    let date: Date
    let mealType: String
}
