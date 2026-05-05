import Fluent
import Vapor

struct UserProfileDTO: Content {
    let id: Int?
    let userId: Int
    let gender: String
    let dateOfBirth: Date
    let height: Double
    let currentWeight: Double
    let goalWeight: Double
    let activityLevel: String
    let dailyCalorieGoal: Double
    let dailyProteinGoal: Double
    let dailyFatGoal: Double
    let dailyCarbGoal: Double
    let isAppleHealthSyncEnabled: Bool
    let name: String
}

struct UserProfileController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let profiles = routes.grouped("api", "profiles")
        profiles.get(use: getAll)
        profiles.post(use: create)
        profiles.put(":id", use: update)
        profiles.delete(":id", use: delete)
    }

    func getAll(req: Request) async throws -> [UserProfile] {
        if let userId = req.query[Int.self, at: "userId"] {
            return try await UserProfile.query(on: req.db)
                .filter(\.$userId == userId)
                .all()
        }
        return try await UserProfile.query(on: req.db).all()
    }

    func create(req: Request) async throws -> UserProfile {
        let input = try req.content.decode(UserProfileDTO.self)
        
        let profile = UserProfile()
        profile.userId = input.userId
        profile.gender = input.gender
        profile.dateOfBirth = input.dateOfBirth
        profile.height = input.height
        profile.currentWeight = input.currentWeight
        profile.goalWeight = input.goalWeight
        profile.activityLevel = input.activityLevel
        profile.dailyCalorieGoal = input.dailyCalorieGoal
        profile.dailyProteinGoal = input.dailyProteinGoal
        profile.dailyFatGoal = input.dailyFatGoal
        profile.dailyCarbGoal = input.dailyCarbGoal
        profile.isAppleHealthSyncEnabled = input.isAppleHealthSyncEnabled
        profile.name = input.name
        
        try await profile.save(on: req.db)
        return profile
    }

    func update(req: Request) async throws -> UserProfile {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(UserProfileDTO.self) // ВИКОРИСТОВУЄМО DTO
        guard let profile = try await UserProfile.find(id, on: req.db) else { throw Abort(.notFound) }

        profile.userId = input.userId
        profile.gender = input.gender
        profile.dateOfBirth = input.dateOfBirth 
        profile.height = input.height
        profile.currentWeight = input.currentWeight
        profile.goalWeight = input.goalWeight
        profile.activityLevel = input.activityLevel
        profile.dailyCalorieGoal = input.dailyCalorieGoal
        profile.dailyProteinGoal = input.dailyProteinGoal
        profile.dailyFatGoal = input.dailyFatGoal
        profile.dailyCarbGoal = input.dailyCarbGoal
        profile.isAppleHealthSyncEnabled = input.isAppleHealthSyncEnabled
        profile.name = input.name

        try await profile.update(on: req.db)
        return profile
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let profile = try await UserProfile.find(id, on: req.db) else { throw Abort(.notFound) }
        try await profile.delete(on: req.db)
        return .noContent
    }
}
