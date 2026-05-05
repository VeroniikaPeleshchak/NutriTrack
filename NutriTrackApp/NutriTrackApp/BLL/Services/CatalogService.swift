import Foundation

class CatalogService {
    static let shared = CatalogService()
    private init() {}
    
    func searchProducts(query: String) async throws -> [ProductDTO] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return [] }
        return try await CatalogRepository.shared.searchProducts(query: cleanQuery)
    }
    
    func getProductByBarcode(_ barcode: String) async throws -> ProductDTO? {
        return try await CatalogRepository.shared.getProductByBarcode(barcode)
    }
    
    func createCustomProduct(name: String, calories: Double, proteins: Double, fats: Double, carbs: Double) async throws -> ProductDTO {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Потрібна авторизація"])
        }
        
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            throw NSError(domain: "ValidationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Введіть назву страви"])
        }
        guard calories >= 0, proteins >= 0, fats >= 0, carbs >= 0 else {
            throw NSError(domain: "ValidationError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Нутрієнти не можуть бути від'ємними"])
        }
        
        let newProduct = ProductDTO(
            id: nil, name: cleanName, calories: calories, proteins: proteins,
            carbs: carbs, fats: fats, barcode: nil, isApproved: false, createdByUserId: userId
        )
        
        return try await CatalogRepository.shared.saveCustomProduct(newProduct)
    }
    
    func deleteProduct(productId: Int) async throws {
        guard AuthManager.shared.isAuthenticated else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Потрібна авторизація"])
        }
        try await CatalogRepository.shared.deleteProduct(id: productId)
    }
}
