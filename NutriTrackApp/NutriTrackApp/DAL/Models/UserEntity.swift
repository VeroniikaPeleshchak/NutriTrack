import Foundation

struct UserEntity: Codable {
    let id: Int?
    let email: String
    let role: String
    let passwordHash: String?
    let name: String
}
