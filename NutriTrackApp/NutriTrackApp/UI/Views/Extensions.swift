import SwiftUI
import UIKit

// MARK: - Ховання клавіатури
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Валідація Даних
extension String {
    
    // Перетворення тексту з комою або крапкою на число
    func toDouble() -> Double? {
        let formatted = self.replacingOccurrences(of: ",", with: ".")
        return Double(formatted)
    }
    
    // 1. Email
    var isValidEmail: Bool {
        let emailRegex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: self.trimmingCharacters(in: .whitespaces))
    }
    
    // 2. Пароль (Мінімум 6 символів, без пробілів)
    var isValidPassword: Bool {
        let trimmed = self.trimmingCharacters(in: .whitespaces)
        return trimmed.count >= 6 && !self.contains(" ")
    }
    
    // 3. Ім'я (Тільки літери (українські + англійські), пробіли та дефіси. Ніяких цифр)
    var isValidName: Bool {
        let nameRegex = "^[a-zA-Zа-яА-ЯіІїЇєЄґҐ\\s-]{2,50}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", nameRegex)
        return predicate.evaluate(with: self.trimmingCharacters(in: .whitespaces))
    }
    
    // 4. Харчова цінність (НА 100 ГРАМІВ)
    var isValidCalories: Bool {
        guard let value = self.toDouble() else { return false }
        return value >= 0 && value <= 1000
    }
    
    var isValidMacro: Bool {
        guard let value = self.toDouble() else { return false }
        return value >= 0 && value <= 100
    }
    
    // 5. Порція (від 1 грама до 3 кг за один раз)
    var isValidPortion: Bool {
        guard let value = self.toDouble() else { return false }
        return value > 0 && value <= 3000
    }
    
    // 6. Фізичні параметри тіла
    var isValidWeight: Bool {
        guard let value = self.toDouble() else { return false }
        return value >= 20.0 && value <= 300.0
    }
    
    var isValidHeight: Bool {
        guard let value = self.toDouble() else { return false }
        return value >= 50.0 && value <= 250.0
    }
    
    var isValidAge: Bool {
        guard let value = Int(self.trimmingCharacters(in: .whitespaces)) else { return false }
        return value >= 10 && value <= 120
    }
    
    var isValidMeasurement: Bool {
        guard let value = self.toDouble() else { return false }
        return value >= 30.0 && value <= 300.0 
    }
}
