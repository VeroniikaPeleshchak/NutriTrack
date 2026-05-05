import Foundation

class ExportService {
    static let shared = ExportService()
    private init() {}
    
    func exportDiaryToCSV() async throws -> URL {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований"])
        }
        
        // ВИПРАВЛЕНО: Запитуємо щоденник ТІЛЬКИ для поточного юзера
        let userEntries = try await TrackingRepository.shared.getDiaryEntries(userId: userId)
        let allProducts = try await CatalogRepository.shared.getProducts()
        
        var csvString = "Дата,Прийом їжі,Назва продукту,Кількість (г/мл),Калорії\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        for entry in userEntries {
            guard let entryId = entry.id else { continue }
            let dateStr = dateFormatter.string(from: entry.date)
            
            let consumedHere = try await TrackingRepository.shared.getConsumedProducts(diaryEntryId: entryId)
            
            for consumed in consumedHere {
                if let product = allProducts.first(where: { $0.id == consumed.productId }) {
                    let nutrition = PortionCalculator.shared.calculateNutrition(for: product, weightGrams: consumed.amount)
                    
                    let safeProductName = product.name.replacingOccurrences(of: ",", with: " ")
                    let line = "\(dateStr),\(entry.mealType),\(safeProductName),\(consumed.amount),\(String(format: "%.1f", nutrition.calories))\n"
                    
                    csvString.append(line)
                }
            }
        }
        
        let fileName = "NutriTrack_Export_\(dateFormatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
        
        return tempURL
    }
}
