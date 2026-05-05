import Fluent
import Vapor

final class DiaryEntry: Model, Content, @unchecked Sendable {
    static let schema = "DiaryEntries"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "UserId")
    var userId: Int
    
    @Field(key: "Date")
    var date: Date
    
    @Field(key: "MealType")
    var mealType: String
    
    init() {}
}
