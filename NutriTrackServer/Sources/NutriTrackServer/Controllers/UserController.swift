import Fluent
import Vapor

// MARK: - DTOs
struct RegisterRequest: Content {
    let email: String
    let passwordHash: String
    let name: String
}

struct LoginRequest: Content {
    let email: String
    let passwordHash: String
}

struct AppleLoginRequest: Content {
    let identityToken: String
    let email: String?
    let name: String?
}

struct AuthResponse: Content {
    let token: String
    let user: User
}

struct UpdateUserRequest: Content {
    let name: String
    let role: String?
}

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let auth = routes.grouped("api", "auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
        auth.post("apple", use: loginWithApple)
        auth.get("me", use: getCurrentUser)
        auth.post("logout", use: logout)
        
        let users = routes.grouped("api", "users")
        users.put(":id", use: update)
        users.delete(":id", use: deleteAccount)
    }

    // MARK: - 1. Реєстрація
    func register(req: Request) async throws -> AuthResponse {
        let input = try req.content.decode(RegisterRequest.self)
        
        if try await User.query(on: req.db).filter(\.$email == input.email).first() != nil {
            throw Abort(.conflict, reason: "Користувач із таким email вже існує")
        }

        let user = User()
        user.email = input.email
        user.passwordHash = try req.password.hash(input.passwordHash)
        user.role = "Користувач"
        user.name = input.name
        
        try await user.save(on: req.db)
        let token = "token_\(user.id!)_\(UUID().uuidString)" // Тимчасово вшиваємо ID в токен для роботи /me
        
        user.passwordHash = ""
        return AuthResponse(token: token, user: user)
    }

    // MARK: - 2. Вхід
    func login(req: Request) async throws -> AuthResponse {
        let input = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() else {
            throw Abort(.unauthorized, reason: "Невірний email або пароль")
        }
        
        let isValid = try req.password.verify(input.passwordHash, created: user.passwordHash)
        guard isValid else {
            throw Abort(.unauthorized, reason: "Невірний email або пароль")
        }
        
        let token = "token_\(user.id!)_\(UUID().uuidString)"
        user.passwordHash = ""
        return AuthResponse(token: token, user: user)
    }

    // MARK: - 3. Вхід через Apple ID
    func loginWithApple(req: Request) async throws -> AuthResponse {
        let input = try req.content.decode(AppleLoginRequest.self)
        
        if let email = input.email, let existingUser = try await User.query(on: req.db).filter(\.$email == email).first() {
            let token = "token_\(existingUser.id!)_\(UUID().uuidString)"
            existingUser.passwordHash = ""
            return AuthResponse(token: token, user: existingUser)
        }
        
        guard let newEmail = input.email else {
            throw Abort(.badRequest, reason: "Не вдалося отримати email від Apple")
        }
        
        let newUser = User()
        newUser.email = newEmail
        newUser.passwordHash = try req.password.hash(UUID().uuidString)
        newUser.role = "Користувач"
        newUser.name = input.name ?? "Користувач Apple"
        
        try await newUser.save(on: req.db)
        let token = "token_\(newUser.id!)_\(UUID().uuidString)"
        
        newUser.passwordHash = ""
        return AuthResponse(token: token, user: newUser)
    }

    // MARK: - 4. Отримання себе
    func getCurrentUser(req: Request) async throws -> User {
        guard let bearer = req.headers.bearerAuthorization,
              let idString = bearer.token.split(separator: "_").dropFirst().first,
              let userId = Int(idString),
              let user = try await User.find(userId, on: req.db) else {
            throw Abort(.unauthorized, reason: "Токен недійсний або користувача не знайдено")
        }
        
        user.passwordHash = ""
        return user
    }

    // MARK: - 5. Вихід
    func logout(req: Request) async throws -> HTTPStatus {
        return .ok
    }

    // MARK: - 6. Оновлення даних та Видалення Акаунту
    func update(req: Request) async throws -> User {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        let input = try req.content.decode(UpdateUserRequest.self)
        guard let user = try await User.find(id, on: req.db) else { throw Abort(.notFound) }
            
        user.name = input.name
        if let role = input.role { user.role = role }
            
        try await user.update(on: req.db)
        user.passwordHash = ""
        return user
    }

    func deleteAccount(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: Int.self) else { throw Abort(.badRequest) }
        guard let user = try await User.find(id, on: req.db) else { throw Abort(.notFound) }
        
        try await user.delete(on: req.db)
        return .noContent
    }
}
