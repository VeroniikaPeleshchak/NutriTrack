import Fluent

// MARK: - 1. Міграція для Users
struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("Users")
            .field("Id", .int, .identifier(auto: true))
            .field("Email", .string, .required)
            .field("PasswordHash", .string, .required)
            .field("Role", .string, .required)
            .field("Name", .string, .required)
            .unique(on: "Email")
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("Users").delete()
    }
}

// MARK: - 2. Міграція для UserProfiles
struct CreateUserProfile: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("UserProfiles")
            .field("Id", .int, .identifier(auto: true))
            .field("UserId", .int, .required, .references("Users", "Id", onDelete: .cascade))
            .field("Gender", .string, .required)
            .field("DateOfBirth", .datetime, .required)
            .field("Height", .double, .required)
            .field("CurrentWeight", .double, .required)
            .field("GoalWeight", .double, .required)
            .field("ActivityLevel", .string, .required)
            .field("DailyCalorieGoal", .double, .required)
            .field("DailyProteinGoal", .double, .required)
            .field("DailyFatGoal", .double, .required)
            .field("DailyCarbGoal", .double, .required)
            .field("IsAppleHealthSyncEnabled", .bool, .required)
            .field("Name", .string, .required)
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("UserProfiles").delete()
    }
}

// MARK: - 3. Міграція для Products
struct CreateProduct: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("Products")
            .field("Id", .int, .identifier(auto: true))
            .field("Name", .string, .required)
            .field("Calories", .double, .required)
            .field("Proteins", .double, .required)
            .field("Carbs", .double, .required)
            .field("Fats", .double, .required)
            .field("Barcode", .string)
            .field("IsApproved", .bool, .required)
            .field("CreatedByUserId", .int, .references("Users", "Id", onDelete: .setNull))
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("Products").delete()
    }
}

// MARK: - 4. Міграція для DiaryEntries
struct CreateDiaryEntry: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("DiaryEntries")
            .field("Id", .int, .identifier(auto: true))
            .field("UserId", .int, .required, .references("Users", "Id", onDelete: .cascade))
            .field("Date", .datetime, .required)
            .field("MealType", .string, .required)
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("DiaryEntries").delete()
    }
}

// MARK: - 5. Міграція для ConsumedProducts
struct CreateConsumedProduct: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("ConsumedProducts")
            .field("Id", .int, .identifier(auto: true))
            .field("DiaryEntryId", .int, .required, .references("DiaryEntries", "Id", onDelete: .cascade))
            .field("ProductId", .int, .required, .references("Products", "Id", onDelete: .cascade))
            .field("Amount", .double, .required)
            .field("MeasurementUnit", .string, .required)
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("ConsumedProducts").delete()
    }
}

// MARK: - 6. Міграція для MeasurementLogs
struct CreateMeasurementLog: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("MeasurementLogs")
            .field("Id", .int, .identifier(auto: true))
            .field("UserId", .int, .required, .references("Users", "Id", onDelete: .cascade))
            .field("Date", .datetime, .required)
            .field("WeightKg", .double, .required)
            .field("WaistCm", .double)
            .field("ChestCm", .double)
            .field("HipsCm", .double)
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("MeasurementLogs").delete()
    }
}

// MARK: - 7. Міграція для ActivityLogs
struct CreateActivityLog: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("ActivityLogs")
            .field("Id", .int, .identifier(auto: true))
            .field("UserId", .int, .required, .references("Users", "Id", onDelete: .cascade))
            .field("Date", .datetime, .required)
            .field("Steps", .int, .required)
            .field("BurnedCalories", .double, .required)
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("ActivityLogs").delete()
    }
}

// MARK: - 8. Міграція для WaterLogs
struct CreateWaterLog: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("WaterLogs")
            .field("Id", .int, .identifier(auto: true))
            .field("UserId", .int, .required, .references("Users", "Id", onDelete: .cascade))
            .field("Date", .datetime, .required)
            .field("AmountMl", .int, .required)
            .create()
    }
    func revert(on database: any Database) async throws {
        try await database.schema("WaterLogs").delete()
    }
}

// MARK: - 9. Міграція для оновлення Products (Додавання IsRejected)
struct AddIsRejectedToProduct: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("Products")
            .field("IsRejected", .bool, .required, .custom("DEFAULT false"))
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("Products")
            .deleteField("IsRejected")
            .update()
    }
}
