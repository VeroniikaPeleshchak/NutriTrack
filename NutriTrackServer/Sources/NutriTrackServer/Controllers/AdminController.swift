import Fluent
import Vapor

struct AdminStatsDTO: Content {
    let activeUsers: Int
    let totalProducts: Int
    let pendingRequests: Int
}

struct AdminController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let admin = routes.grouped("api", "admin")
        
        admin.get("stats", use: getDashboardStats)
        
        let products = admin.grouped("products")
        
        products.get(use: getAllProducts)
        products.post(use: addProduct)
        products.get("pending", use: getPendingProducts)
        
        let productWithId = products.grouped(":id")
        productWithId.put(use: updateProduct)
        productWithId.delete(use: deleteProduct)
        productWithId.patch("approve", use: approveProduct)
        productWithId.patch("reject", use: rejectProduct)
    }

    func getDashboardStats(req: Request) async throws -> AdminStatsDTO {
        let usersCount = try await User.query(on: req.db).count()
        
        let totalProductsCount = try await Product.query(on: req.db)
            .filter(\.$isApproved == true)
            .count()
        
        let pendingCount = try await Product.query(on: req.db)
            .filter(\.$isApproved == false)
            .count()
        
        return AdminStatsDTO(
            activeUsers: usersCount,
            totalProducts: totalProductsCount,
            pendingRequests: pendingCount
        )
    }


    func getAllProducts(req: Request) async throws -> [Product] {
        return try await Product.query(on: req.db).all()
    }

    func getPendingProducts(req: Request) async throws -> [Product] {
        return try await Product.query(on: req.db)
            .filter(\.$isApproved == false)
            .filter(\.$isRejected == false)
            .all()
    }

    func approveProduct(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let product = try await Product.find(id, on: req.db) else { throw Abort(.notFound) }
        
        product.isApproved = true
        try await product.update(on: req.db)
        
        return .ok
    }

    func rejectProduct(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let product = try await Product.find(id, on: req.db) else { throw Abort(.notFound) }
        
        product.isRejected = true
        product.isApproved = false
        try await product.update(on: req.db)
        
        return .noContent
    }

    func addProduct(req: Request) async throws -> Product {
        let input = try req.content.decode(ProductDTO.self)
        
        let product = Product()
        product.name = input.name
        product.calories = input.calories
        product.proteins = input.proteins
        product.carbs = input.carbs
        product.fats = input.fats
        product.barcode = input.barcode
        product.isApproved = true
        product.isRejected = false
        product.createdByUserId = input.createdByUserId
        
        try await product.save(on: req.db)
        return product
    }

    func updateProduct(req: Request) async throws -> Product {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(ProductDTO.self)
        guard let product = try await Product.find(id, on: req.db) else { throw Abort(.notFound) }
        
        product.name = input.name
        product.calories = input.calories
        product.proteins = input.proteins
        product.carbs = input.carbs
        product.fats = input.fats
        product.barcode = input.barcode
        product.isApproved = input.isApproved
        product.isRejected = input.isRejected ?? false
        
        try await product.update(on: req.db)
        return product
    }

    func deleteProduct(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let product = try await Product.find(id, on: req.db) else { throw Abort(.notFound) }
        
        try await product.delete(on: req.db)
        return .noContent
    }
}
