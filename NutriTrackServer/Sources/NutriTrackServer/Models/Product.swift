import Fluent
import Vapor

final class Product: Model, Content, @unchecked Sendable {
    static let schema = "Products"
    
    @ID(custom: "Id", generatedBy: .database)
    var id: Int?
    
    @Field(key: "Name")
    var name: String
    
    @Field(key: "Calories")
    var calories: Double
    
    @Field(key: "Proteins")
    var proteins: Double
    
    @Field(key: "Carbs")
    var carbs: Double
    
    @Field(key: "Fats")
    var fats: Double
    
    @OptionalField(key: "Barcode")
    var barcode: String?
    
    @Field(key: "IsApproved")
    var isApproved: Bool
    
    @Field(key: "IsRejected")
    var isRejected: Bool
    
    @OptionalField(key: "CreatedByUserId")
    var createdByUserId: Int?
    
    init() {}
}
