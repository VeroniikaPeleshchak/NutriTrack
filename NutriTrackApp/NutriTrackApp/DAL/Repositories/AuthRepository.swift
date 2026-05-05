import Foundation

class AuthRepository {
    static let shared = AuthRepository()
    private init() {}
    
    // MARK: - 1. Реєстрація
    func register(request: RegisterRequestDTO) async throws -> AuthResponseDTO {
        return try await NetworkManager.shared.sendData(to: "/api/auth/register", method: "POST", data: request)
    }
    
    // MARK: - 2. Класичний вхід
    func login(request: LoginRequestDTO) async throws -> AuthResponseDTO {
        return try await NetworkManager.shared.sendData(to: "/api/auth/login", method: "POST", data: request)
    }
    
    // MARK: - 3. Вхід через Apple ID
    func loginWithApple(request: AppleLoginRequestDTO) async throws -> AuthResponseDTO {
        return try await NetworkManager.shared.sendData(to: "/api/auth/apple", method: "POST", data: request)
    }
    
    // MARK: - 4. Отримання даних поточного користувача
    func getCurrentUser() async throws -> UserDTO {
        return try await NetworkManager.shared.fetchSingle(from: "/api/auth/me")
    }
    
    // MARK: - 5. Вихід
    func logout() async throws {
        try await NetworkManager.shared.sendRequest(to: "/api/auth/logout", method: "POST")
    }
    
    // MARK: - 6. Видалення акаунту
    func deleteAccount(userId: Int) async throws {
        try await NetworkManager.shared.sendRequest(to: "/api/users/\(userId)", method: "DELETE")
    }
}
