import Foundation

// MARK: - Допоміжні типи для точності
enum ActivityLevel: Double {
    case sedentary = 1.2      // Сидячий спосіб життя (майже без спорту)
    case light = 1.375        // Легка активність (тренування 1-3 рази на тиждень)
    case moderate = 1.55      // Помірна активність (3-5 разів на тиждень)
    case active = 1.725       // Висока активність (6-7 разів на тиждень)
    case veryActive = 1.9     // Дуже висока активність (важка фізична робота/2 тренування на день)
}

enum UserGoal {
    case loseWeight
    case maintain
    case gainWeight
}

struct DailyNorms {
    let calories: Double
    let proteins: Double
    let fats: Double
    let carbs: Double
}

// MARK: - Калькулятор
class NutriCalculator {
    static let shared = NutriCalculator()
    private init() {}
    
    func calculateNorms(weightKg: Double, heightCm: Double, age: Int, isMale: Bool, activity: ActivityLevel, goal: UserGoal) -> DailyNorms {
        
        var bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * Double(age))
        bmr += isMale ? 5.0 : -161.0
        
        var calories = bmr * activity.rawValue

        switch goal {
        case .loseWeight:
            calories -= 500
            let minLimit = isMale ? 1500.0 : 1200.0
            if calories < minLimit { calories = minLimit }
            
        case .maintain:
            break
            
        case .gainWeight:
            calories += 500
        }

        let proteinsGrams = (calories * 0.30) / 4.0
        let fatsGrams = (calories * 0.30) / 9.0
        let carbsGrams = (calories * 0.40) / 4.0
        
        return DailyNorms(
            calories: calories.rounded(),
            proteins: proteinsGrams.rounded(),
            fats: fatsGrams.rounded(),
            carbs: carbsGrams.rounded()
        )
    }
}
