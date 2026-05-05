import Foundation

struct NutritionValues {
    let calories: Double
    let proteins: Double
    let fats: Double
    let carbs: Double
}

class PortionCalculator {
    static let shared = PortionCalculator()
    private init() {}
    
    func calculateNutrition(for product: ProductDTO, weightGrams: Double) -> NutritionValues {
        guard weightGrams > 0 else {
            return NutritionValues(calories: 0, proteins: 0, fats: 0, carbs: 0)
        }
        
        let factor = weightGrams / 100.0
        
        return NutritionValues(
            calories: (product.calories * factor).rounded(toPlaces: 1),
            proteins: (product.proteins * factor).rounded(toPlaces: 1),
            fats: (product.fats * factor).rounded(toPlaces: 1),
            carbs: (product.carbs * factor).rounded(toPlaces: 1)
        )
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
