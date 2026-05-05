import Fluent
import Vapor

struct WaterLogDTO: Content {
    let id: Int?
    let userId: Int
    let date: Date
    let amountMl: Int
}

struct WaterLogController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let water = routes.grouped("api", "water")
        water.get(use: getAll)
        water.post(use: create)
        water.put(":id", use: update)
        water.delete(":id", use: delete)
    }

    func getAll(req: Request) async throws -> [WaterLog] {
        if let userId = req.query[Int.self, at: "userId"] {
            return try await WaterLog.query(on: req.db).filter(\.$userId == userId).all()
        }
        return try await WaterLog.query(on: req.db).all()
    }

    func create(req: Request) async throws -> WaterLog {
        let input = try req.content.decode(WaterLogDTO.self)
        
        let log = WaterLog()
        log.userId = input.userId
        log.date = input.date
        log.amountMl = input.amountMl
        
        try await log.save(on: req.db)
        return log
    }
    
    func update(req: Request) async throws -> WaterLog {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(WaterLogDTO.self) 
        guard let log = try await WaterLog.find(id, on: req.db) else { throw Abort(.notFound) }
        
        log.userId = input.userId
        log.date = input.date
        log.amountMl = input.amountMl
        
        try await log.update(on: req.db)
        return log
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let log = try await WaterLog.find(id, on: req.db) else { throw Abort(.notFound) }
        try await log.delete(on: req.db)
        return .noContent
    }
}
