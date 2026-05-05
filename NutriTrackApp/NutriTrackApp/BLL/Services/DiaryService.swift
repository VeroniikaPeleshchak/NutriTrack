import Foundation

struct MealSectionUI: Identifiable {
    let id = UUID()
    let mealType: String
    var consumedItems: [ConsumedItemUI]
    
    var totalSectionCalories: Double {
        consumedItems.reduce(0) { $0 + $1.totalCalories }
    }
}

struct ConsumedItemUI: Identifiable {
    let id = UUID()
    let consumedId: Int
    let product: ProductDTO
    let amount: Double
    let totalCalories: Double
}

class DiaryService {
    static let shared = DiaryService()
    private init() {}
    
    func getDiary(for date: Date) async throws -> [MealSectionUI] {
        guard let userId = AuthManager.shared.currentUserId else { return [] }
        
        let allEntries = try await TrackingRepository.shared.getDiaryEntries(userId: userId)
        let allProducts = try await CatalogRepository.shared.getProducts() // Кешуємо продукти для швидкості
        
        let calendar = Calendar.current
        let targetEntries = allEntries.filter { calendar.isDate($0.date, inSameDayAs: date) }
        
        let mealTypes = ["Сніданок", "Обід", "Вечеря", "Перекус"]
        var sectionsDict: [String: MealSectionUI] = [:]
        
        for type in mealTypes {
            sectionsDict[type] = MealSectionUI(mealType: type, consumedItems: [])
        }
        
        for entry in targetEntries {
            guard let entryId = entry.id else { continue }
            
            let consumedHere = try await TrackingRepository.shared.getConsumedProducts(diaryEntryId: entryId)
            
            for consumed in consumedHere {
                if let product = allProducts.first(where: { $0.id == consumed.productId }),
                   let consumedId = consumed.id {
                    let nutrition = PortionCalculator.shared.calculateNutrition(for: product, weightGrams: consumed.amount)
                    
                    let newItem = ConsumedItemUI(
                        consumedId: consumedId,
                        product: product,
                        amount: consumed.amount,
                        totalCalories: nutrition.calories
                    )
                    
                    sectionsDict[entry.mealType]?.consumedItems.append(newItem)
                }
            }
        }
        
        return mealTypes.compactMap { sectionsDict[$0] }
    }
    
    func addProductToDiary(product: ProductDTO, amount: Double, mealType: String, date: Date = Date()) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Авторизуйтесь"])
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        let entry = try await TrackingRepository.shared.getOrCreateDiaryEntry(
            userId: userId,
            date: startOfDay,
            mealType: mealType
        )
        
        guard let entryId = entry.id else { return }
        
        let newConsumed = ConsumedProductDTO(
            id: nil,
            diaryEntryId: entryId,
            productId: product.id!,
            amount: amount,
            measurementUnit: "г"
        )
        
        try await TrackingRepository.shared.saveConsumedProduct(newConsumed)
    }
    
    func deleteConsumedProduct(id: Int) async throws {
        try await TrackingRepository.shared.deleteConsumedProduct(id: id)
    }
}
