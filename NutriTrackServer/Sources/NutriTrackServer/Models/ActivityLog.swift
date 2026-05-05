import Fluent
import Vapor

final class ActivityLog: Model, Content, @unchecked Sendable {
    static let schema = "ActivityLogs"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "UserId")
    var userId: Int
    
    @Field(key: "Date")
    var date: Date
    
    @Field(key: "Steps")
    var steps: Int
    
    @Field(key: "BurnedCalories")
    var burnedCalories: Double
    
    init() {}
}
