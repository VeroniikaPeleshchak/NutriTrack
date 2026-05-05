import Vapor

func routes(_ app: Application) throws {
    
    try app.register(collection: UserController())
    try app.register(collection: UserProfileController())
    try app.register(collection: ProductController())
    try app.register(collection: DiaryEntryController())
    try app.register(collection: ConsumedProductController())
    try app.register(collection: WaterLogController())
    try app.register(collection: MeasurementLogController())
    try app.register(collection: ActivityLogController())
    try app.register(collection: AdminController())
    
    app.get("hello") { req async in
        "Сервер NutriTrack працює на всі 100%!"
    }
}
