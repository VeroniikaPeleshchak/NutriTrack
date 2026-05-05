import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "Users"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "Email")
    var email: String
    
    @Field(key: "PasswordHash")
    var passwordHash: String
    
    @Field(key: "Role")
    var role: String
    
    @Field(key: "Name")
    var name: String
    
    init() {}
}
