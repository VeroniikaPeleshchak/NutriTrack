import Foundation
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    
    @Published var gender: String = "Жінка"
    @Published var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var height = ""
    @Published var currentWeight = ""
    @Published var goalWeight = ""
    @Published var activityLevel = "Cидячий спосіб життя"
    
    @Published var currentStep = 1
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldNavigateToMain = false
    
    let activityOptions = [
        "Cидячий спосіб життя",
        "Легка активність",
        "Помірна активність",
        "Висока активність",
        "Дуже висока активність"
    ]
    
    // MARK: - Дії користувача
    
    func goToStep2() async -> Bool {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Заповніть усі поля для реєстрації"
            return false
        }
        guard password == confirmPassword else {
            errorMessage = "Паролі не співпадають"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await AuthService.shared.register(email: email, passwordRaw: password, name: name)
            currentStep = 2
            isLoading = false
            return true
        } catch {
            errorMessage = "Помилка реєстрації: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func finishSetup() async {
        // Жорстка перевірка через Extensions
        guard height.isValidHeight else {
            errorMessage = "Введіть коректний зріст (від 50 до 250 см)."
            return
        }
        guard currentWeight.isValidWeight else {
            errorMessage = "Введіть коректну поточну вагу (від 20 до 300 кг)."
            return
        }
        guard goalWeight.isValidWeight else {
            errorMessage = "Введіть коректну цільову вагу (від 20 до 300 кг)."
            return
        }
        
        let h = height.toDouble() ?? 0
        let cw = currentWeight.toDouble() ?? 0
        let gw = goalWeight.toDouble() ?? 0
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await ProfileService.shared.setupProfile(
                name: name,
                gender: gender,
                dateOfBirth: dateOfBirth,
                height: h,
                currentWeight: cw,
                goalWeight: gw,
                activityLevelStr: activityLevel
            )
            
            shouldNavigateToMain = true
        } catch {
            errorMessage = "Не вдалося зберегти профіль."
        }
        
        isLoading = false
    }
}
