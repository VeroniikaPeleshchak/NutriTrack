import Fluent
import Vapor

struct ProductDTO: Content {
    let name: String
    let calories: Double
    let proteins: Double
    let carbs: Double
    let fats: Double
    let barcode: String?
    let isApproved: Bool
    let createdByUserId: Int?
    let isRejected: Bool?
}

struct ProductController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let products = routes.grouped("api", "products")
        products.get(use: getAll)
        products.get("barcode", ":barcode", use: getByBarcode)
        products.post(use: create)
        products.put(":id", use: update)
        products.delete(":id", use: delete)
    }
    
    
    // MARK: - 1. Отримання продуктів (з урахуванням модерації)
    func getAll(req: Request) async throws -> [Product] {
        let query = Product.query(on: req.db)
        let currentUserId = req.query[Int.self, at: "userId"]
        
        query.group(.or) { orGroup in
            // УМОВА 1: Продукт схвалений і НЕ відхилений (бачать усі)
            orGroup.group(.and) { andGroup in
                andGroup.filter(\.$isApproved == true)
                andGroup.filter(\.$isRejected == false)
            }
            
            // УМОВА 2: Це власний продукт користувача (бачить тільки автор, статус неважливий)
            if let userId = currentUserId {
                orGroup.filter(\.$createdByUserId == userId)
            }
        }
        
        // Фільтр пошуку за назвою або штрихкодом
        if let searchTerm = req.query[String.self, at: "search"] {
            query.group(.and) { andGroup in
                andGroup.group(.or) { searchOr in
                    searchOr.filter(\.$name ~~ searchTerm)
                    searchOr.filter(\.$barcode == searchTerm)
                }
            }
        }
        
        return try await query.all()
    }
    
    // MARK: - 2. Пошук точного штрихкоду
    func getByBarcode(req: Request) async throws -> Product {
        guard let barcode = req.parameters.get("barcode") else {
            throw Abort(.badRequest)
        }
        
        guard let product = try await Product.query(on: req.db)
            .filter(\.$barcode == barcode)
            .first() else {
            throw Abort(.notFound, reason: "Продукт з таким штрихкодом не знайдено")
        }
        
        return product
    }
    
    // MARK: - 3. Створення
    func create(req: Request) async throws -> Product {
        let input = try req.content.decode(ProductDTO.self)
        
        let product = Product()
        product.name = input.name
        product.calories = input.calories
        product.proteins = input.proteins
        product.carbs = input.carbs
        product.fats = input.fats
        product.barcode = input.barcode
        product.isApproved = input.isApproved
        product.isRejected = input.isRejected ?? false
        product.createdByUserId = input.createdByUserId
        
        try await product.save(on: req.db)
        return product
    }
    
    // MARK: - 4. Оновлення (Адмін може все, юзер — тільки своє неперевірене)
    func update(req: Request) async throws -> Product {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(ProductDTO.self)
        guard let product = try await Product.find(id, on: req.db) else { throw Abort(.notFound) }
        
        let requesterId = input.createdByUserId ?? 0
        let user = try await User.find(requesterId, on: req.db)
        let isAdmin = user?.role == "Адмін"
        
        if product.isApproved && !isAdmin {
            throw Abort(.forbidden, reason: "Схвалені страви може редагувати тільки адмін")
        }
        
        product.name = input.name
        product.calories = input.calories
        product.proteins = input.proteins
        product.carbs = input.carbs
        product.fats = input.fats
        product.barcode = input.barcode
        product.isApproved = input.isApproved
        product.isRejected = input.isRejected ?? false
        product.createdByUserId = input.createdByUserId
        
        try await product.update(on: req.db)
        return product
    }
    
    // MARK: - 5. Видалення
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let product = try await Product.find(id, on: req.db) else { throw Abort(.notFound) }
        
        guard let requesterId = req.query[Int.self, at: "userId"],
              let requester = try await User.find(requesterId, on: req.db) else {
            throw Abort(.unauthorized, reason: "Не вказано ID користувача")
        }
        
        guard let requester = try await User.find(requesterId, on: req.db) else {
            throw Abort(.notFound, reason: "Користувача не знайдено")
        }
        
        let isAdmin = requester.role == "Адмін"
        let isOwner = product.createdByUserId == requesterId
        
        if isAdmin {
        } else if isOwner && !product.isApproved {
        } else {
            throw Abort(.forbidden, reason: "У вас немає прав для видалення цієї страви")
        }
        
        try await product.delete(on: req.db)
        return .noContent
    }
}
