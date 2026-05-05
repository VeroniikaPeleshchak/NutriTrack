import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - AuthService
class AuthService {
    static let shared = AuthService()
    private init() {}
    
    private func hashPassword(_ pass: String) -> String {
        let data = Data(pass.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func login(email: String, passwordRaw: String) async throws {
        let hashedPass = hashPassword(passwordRaw) // Хешуємо тут
        let requestData = LoginRequestDTO(email: email, passwordHash: hashedPass)
        
        let response = try await AuthRepository.shared.login(request: requestData)
        
        AuthManager.shared.currentUser = response.user
        KeychainManager.shared.saveToken(response.token)
        
        print("Успішний вхід! Вітаємо, \(response.user.name)")
    }
    
    func register(email: String, passwordRaw: String, name: String) async throws {
        let hashedPass = hashPassword(passwordRaw) // Хешуємо тут
        let requestData = RegisterRequestDTO(email: email, passwordHash: hashedPass, name: name)
        
        let response = try await AuthRepository.shared.register(request: requestData)
        
        AuthManager.shared.currentUser = response.user
        KeychainManager.shared.saveToken(response.token)
        
        print("Реєстрація успішна! Вітаємо, \(response.user.name)")
    }
    
    func loginWithApple(identityToken: Data, email: String?, fullName: String?) async throws {
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Помилка читання токена Apple"])
        }
        
        let requestData = AppleLoginRequestDTO(
            identityToken: tokenString,
            email: email,
            name: fullName
        )
        
        let response = try await AuthRepository.shared.loginWithApple(request: requestData)
        
        AuthManager.shared.currentUser = response.user
        KeychainManager.shared.saveToken(response.token)
        
        print("Успішний вхід через Apple! Вітаємо, \(response.user.name)")
    }
    
    func logout() async {
        try? await AuthRepository.shared.logout()
        
        AuthManager.shared.currentUser = nil
        AuthManager.shared.currentUserProfile = nil
        
        KeychainManager.shared.deleteToken()
        
        print("Користувач успішно вийшов з системи, дані очищено.")
    }
    
    func deleteAccount() async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не знайдений"])
        }
        
        try await AuthRepository.shared.deleteAccount(userId: userId)
        
        await logout()
        print("Акаунт користувача успішно видалено.")
    }
}
