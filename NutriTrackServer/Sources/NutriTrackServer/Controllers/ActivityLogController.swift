import Fluent
import Vapor

struct ActivityLogDTO: Content {
    let id: Int?
    let userId: Int
    let date: Date
    let steps: Int
    let burnedCalories: Double
}

struct ActivityLogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let activity = routes.grouped("api", "activity")
        activity.get(use: getAll)
        activity.post(use: create)
        activity.put(":id", use: update)
        activity.delete(":id", use: delete)
    }

    func getAll(req: Request) async throws -> [ActivityLog] {
        if let userId = req.query[Int.self, at: "userId"] {
            return try await ActivityLog.query(on: req.db).filter(\.$userId == userId).all()
        }
        return try await ActivityLog.query(on: req.db).all()
    }

    func create(req: Request) async throws -> ActivityLog {
        let input = try req.content.decode(ActivityLogDTO.self) 
        
        let log = ActivityLog()
        log.userId = input.userId
        log.date = input.date
        log.steps = input.steps
        log.burnedCalories = input.burnedCalories
        
        try await log.save(on: req.db)
        return log
    }

    func update(req: Request) async throws -> ActivityLog {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(ActivityLogDTO.self) // ВИКОРИСТОВУЄМО DTO
        guard let log = try await ActivityLog.find(id, on: req.db) else { throw Abort(.notFound) }
        
        log.userId = input.userId
        log.date = input.date
        log.steps = input.steps
        log.burnedCalories = input.burnedCalories
        
        try await log.update(on: req.db)
        return log
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let log = try await ActivityLog.find(id, on: req.db) else { throw Abort(.notFound) }
        try await log.delete(on: req.db)
        return .noContent
    }
}
