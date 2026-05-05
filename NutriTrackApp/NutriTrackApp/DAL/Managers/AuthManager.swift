import Foundation
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: UserDTO?
    @Published var currentUserProfile: UserProfileDTO?
    
    private init() {}
    
    var isAuthenticated: Bool {
        return currentUser != nil
    }
    
    var currentUserId: Int? {
        return currentUser?.id
    }
    
    // MARK: - Перевірка при старті додатку
    func checkAuthStatus() async {
        guard KeychainManager.shared.getToken() != nil else {
            return
        }
        
        do {
            let user = try await AuthRepository.shared.getCurrentUser()
            self.currentUser = user
            
            if let userId = user.id {
                let profiles = try await TrackingRepository.shared.getProfile(userId: userId)
                self.currentUserProfile = profiles.first
            }
        } catch {
            print("Помилка відновлення сесії (можливо, токен протермінувався): \(error)")
            logout()
        }
    }
    
    // MARK: - Вихід з акаунту
    func logout() {
        KeychainManager.shared.deleteToken()
        currentUser = nil
        currentUserProfile = nil
    }
}
