import Fluent
import Vapor

struct ConsumedProductDTO: Content {
    let id: Int?
    let diaryEntryId: Int
    let productId: Int
    let amount: Double
    let measurementUnit: String
}

struct ConsumedProductController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let consumed = routes.grouped("api", "consumed_products")
        consumed.get(use: getAll)
        consumed.post(use: create)
        consumed.put(":id", use: update)
        consumed.delete(":id", use: delete)
    }

    func getAll(req: Request) async throws -> [ConsumedProduct] {
        if let diaryId = req.query[Int.self, at: "diaryEntryId"] {
            return try await ConsumedProduct.query(on: req.db).filter(\.$diaryEntryId == diaryId).all()
        }
        return try await ConsumedProduct.query(on: req.db).all()
    }

    func create(req: Request) async throws -> ConsumedProduct {
        let input = try req.content.decode(ConsumedProductDTO.self)
        
        let product = ConsumedProduct()
        product.diaryEntryId = input.diaryEntryId
        product.productId = input.productId
        product.amount = input.amount
        product.measurementUnit = input.measurementUnit
        
        try await product.save(on: req.db)
        return product
    }

    func update(req: Request) async throws -> ConsumedProduct {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(ConsumedProductDTO.self)
        guard let product = try await ConsumedProduct.find(id, on: req.db) else { throw Abort(.notFound) }
        
        product.diaryEntryId = input.diaryEntryId
        product.productId = input.productId
        product.amount = input.amount
        product.measurementUnit = input.measurementUnit
        
        try await product.update(on: req.db)
        return product
    }

    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let product = try await ConsumedProduct.find(id, on: req.db) else { throw Abort(.notFound) }
        try await product.delete(on: req.db)
        return .noContent
    }
}
