import Fluent
import Vapor

final class MeasurementLog: Model, Content, @unchecked Sendable {
    static let schema = "MeasurementLogs"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "UserId")
    var userId: Int
    
    @Field(key: "Date")
    var date: Date
    
    @Field(key: "WeightKg")
    var weightKg: Double
    
    @OptionalField(key: "WaistCm")
    var waistCm: Double?
    
    @OptionalField(key: "ChestCm")
    var chestCm: Double?
    
    @OptionalField(key: "HipsCm")
    var hipsCm: Double?
    
    init() {}
}
