import Fluent
import Vapor

struct MeasurementLogDTO: Content {
    let id: Int?
    let userId: Int
    let date: Date
    let weightKg: Double
    let waistCm: Double?
    let chestCm: Double?
    let hipsCm: Double?
}

struct MeasurementLogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let measurements = routes.grouped("api", "measurements")
        measurements.get(use: getAll)
        measurements.post(use: create)
        measurements.put(":id", use: update)
        measurements.delete(":id", use: delete)
    }

    func getAll(req: Request) async throws -> [MeasurementLog] {
        if let userId = req.query[Int.self, at: "userId"] {
            return try await MeasurementLog.query(on: req.db).filter(\.$userId == userId).all()
        }
        return try await MeasurementLog.query(on: req.db).all()
    }

    func create(req: Request) async throws -> MeasurementLog {
        let input = try req.content.decode(MeasurementLogDTO.self) 
        
        let log = MeasurementLog()
        log.userId = input.userId
        log.date = input.date
        log.weightKg = input.weightKg
        log.waistCm = input.waistCm
        log.chestCm = input.chestCm
        log.hipsCm = input.hipsCm
        
        try await log.save(on: req.db)
        return log
    }

    func update(req: Request) async throws -> MeasurementLog {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(MeasurementLogDTO.self) // ВИКОРИСТОВУЄМО DTO
        guard let log = try await MeasurementLog.find(id, on: req.db) else { throw Abort(.notFound) }
        
        log.userId = input.userId
        log.date = input.date
        log.weightKg = input.weightKg
        log.waistCm = input.waistCm
        log.chestCm = input.chestCm
        log.hipsCm = input.hipsCm
        
        try await log.update(on: req.db)
        return log
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let log = try await MeasurementLog.find(id, on: req.db) else { throw Abort(.notFound) }
        try await log.delete(on: req.db)
        return .noContent
    }
}
