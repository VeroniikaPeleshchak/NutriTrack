import Fluent
import Vapor

final class UserProfile: Model, Content, @unchecked Sendable {
    static let schema = "UserProfiles"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "UserId")
    var userId: Int
    
    @Field(key: "Gender")
    var gender: String
    
    @Field(key: "DateOfBirth")
    var dateOfBirth: Date
    
    @Field(key: "Height")
    var height: Double
    
    @Field(key: "CurrentWeight")
    var currentWeight: Double
    
    @Field(key: "GoalWeight")
    var goalWeight: Double
    
    @Field(key: "ActivityLevel")
    var activityLevel: String
    
    @Field(key: "DailyCalorieGoal")
    var dailyCalorieGoal: Double
    
    @Field(key: "DailyProteinGoal")
    var dailyProteinGoal: Double
    
    @Field(key: "DailyFatGoal")
    var dailyFatGoal: Double
    
    @Field(key: "DailyCarbGoal")
    var dailyCarbGoal: Double
    
    @Field(key: "IsAppleHealthSyncEnabled")
    var isAppleHealthSyncEnabled: Bool
    
    @Field(key: "Name")
    var name: String
    
    init() {}
}
