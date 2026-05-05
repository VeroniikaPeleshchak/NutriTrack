import Fluent
import Vapor

struct DiaryEntryDTO: Content {
    let id: Int?
    let userId: Int
    let date: Date
    let mealType: String
}

struct DiaryEntryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let entries = routes.grouped("api", "diary_entries")
        entries.get(use: getAll)
        entries.post(use: create)
        entries.post("find-or-create", use: findOrCreate)
        entries.put(":id", use: update)
        entries.delete(":id", use: delete)
    }

    func getAll(req: Request) async throws -> [DiaryEntry] {
        if let userId = req.query[Int.self, at: "userId"] {
            return try await DiaryEntry.query(on: req.db).filter(\.$userId == userId).all()
        }
        return try await DiaryEntry.query(on: req.db).all()
    }

    func create(req: Request) async throws -> DiaryEntry {
        let input = try req.content.decode(DiaryEntryDTO.self)
        
        let entry = DiaryEntry()
        entry.userId = input.userId
        entry.date = input.date
        entry.mealType = input.mealType
        
        try await entry.save(on: req.db)
        return entry
    }
    
    func findOrCreate(req: Request) async throws -> DiaryEntry {
        let input = try req.content.decode(DiaryEntryDTO.self)
        
        if let existing = try await DiaryEntry.query(on: req.db)
            .filter(\.$userId == input.userId)
            .filter(\.$date == input.date)
            .filter(\.$mealType == input.mealType)
            .first() {
            return existing
        }
        
        let entry = DiaryEntry()
        entry.userId = input.userId
        entry.date = input.date
        entry.mealType = input.mealType
        
        try await entry.save(on: req.db)
        return entry
    }

    func update(req: Request) async throws -> DiaryEntry {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(DiaryEntryDTO.self)
        guard let entry = try await DiaryEntry.find(id, on: req.db) else { throw Abort(.notFound) }
        
        entry.userId = input.userId
        entry.date = input.date
        entry.mealType = input.mealType
        
        try await entry.update(on: req.db)
        return entry
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let entry = try await DiaryEntry.find(id, on: req.db) else { throw Abort(.notFound) }
        try await entry.delete(on: req.db)
        return .noContent
    }
}
