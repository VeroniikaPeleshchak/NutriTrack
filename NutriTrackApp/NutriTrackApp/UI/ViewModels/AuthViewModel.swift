import Foundation
import Combine
import AuthenticationServices

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Дані для UI
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    
    // MARK: - Стан інтерфейсу
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var isRegistrationMode = false
    
    // MARK: - Навігація
    @Published var navigateToDashboard = false
    @Published var navigateToOnboarding = false
    
    // MARK: - Дії користувача
    func authenticate() async {
        if isRegistrationMode {
            await register()
        } else {
            await login()
        }
    }
    
    private func login() async {
        guard validateInputs(isLogin: true) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await AuthService.shared.login(email: email, passwordRaw: password)
            AuthManager.shared.currentUserProfile = try? await ProfileService.shared.getProfile()
            navigateToDashboard = true
        } catch {
            errorMessage = "Невірний email або пароль"
        }
        
        isLoading = false
    }
    
    private func register() async {
        guard validateInputs(isLogin: false) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await AuthService.shared.register(email: email, passwordRaw: password, name: name)
            navigateToOnboarding = true
        } catch {
            errorMessage = "Користувач з таким email вже існує або сталася помилка"
        }
        
        isLoading = false
    }
    
    func handleAppleLogin(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityToken = appleIDCredential.identityToken {
                
                let userEmail = appleIDCredential.email
                let fullName = appleIDCredential.fullName != nil ? "\(appleIDCredential.fullName!.givenName ?? "") \(appleIDCredential.fullName!.familyName ?? "")".trimmingCharacters(in: .whitespaces) : nil
                
                do {
                    try await AuthService.shared.loginWithApple(identityToken: identityToken, email: userEmail, fullName: fullName)
                    
                    if fullName != nil && !fullName!.isEmpty {
                        navigateToOnboarding = true
                    } else {
                        navigateToDashboard = true
                    }
                } catch {
                    errorMessage = "Помилка авторизації через Apple на сервері"
                }
            }
        case .failure(let error):
            errorMessage = "Помилка авторизації Apple: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - ЖОРСТКА ВАЛІДАЦІЯ
    private func validateInputs(isLogin: Bool) -> Bool {
        guard email.isValidEmail else {
            errorMessage = "Введіть коректний Email"
            return false
        }
        
        guard password.isValidPassword else {
            errorMessage = "Пароль має містити мінімум 6 символів (без пробілів)"
            return false
        }
        
        if !isLogin {
            guard name.isValidName else {
                errorMessage = "Ім'я має містити щонайменше 2 літери (без цифр)"
                return false
            }
        }
        
        errorMessage = nil
        return true
    }
}
