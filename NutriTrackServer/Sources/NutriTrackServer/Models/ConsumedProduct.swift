import Fluent
import Vapor

final class ConsumedProduct: Model, Content, @unchecked Sendable {
    static let schema = "ConsumedProducts"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "DiaryEntryId")
    var diaryEntryId: Int
    
    @Field(key: "ProductId")
    var productId: Int
    
    @Field(key: "Amount")
    var amount: Double
    
    @Field(key: "MeasurementUnit")
    var measurementUnit: String
    
    init() {}
}
