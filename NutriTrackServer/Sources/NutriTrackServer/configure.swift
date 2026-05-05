import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    
    let postgresConfig = SQLPostgresConfiguration(
        hostname: "localhost",
        port: 5432,
        username: "postgres",
        password: "n1ka1511",
        database: "NutriTrackDB",
        tls: .disable 
    )
    
    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    
    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserProfile())
    app.migrations.add(CreateProduct())
    app.migrations.add(CreateDiaryEntry())
    app.migrations.add(CreateConsumedProduct())
    app.migrations.add(CreateMeasurementLog())
    app.migrations.add(CreateActivityLog())
    app.migrations.add(CreateWaterLog())
    app.migrations.add(AddIsRejectedToProduct())
    
    try app.autoMigrate().wait()

    try routes(app)
}
