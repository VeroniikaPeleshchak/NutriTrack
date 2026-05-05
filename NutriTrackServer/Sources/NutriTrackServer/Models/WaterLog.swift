import Fluent
import Vapor

final class WaterLog: Model, Content, @unchecked Sendable {
    static let schema = "WaterLogs"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "UserId")
    var userId: Int
    
    @Field(key: "Date")
    var date: Date
    
    @Field(key: "AmountMl")
    var amountMl: Int
    
    init() {}
}
