import Foundation
import Combine

@MainActor
class CatalogViewModel: ObservableObject {
    
    // MARK: - Дані для пошуку
    @Published var searchQuery = ""
    @Published var searchResults: [ProductDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Дані для вибору порції
    @Published var selectedProduct: ProductDTO? = nil
    @Published var portionGramsStr: String = "100"
    
    // MARK: - Дані для створення/редагування власної страви
    @Published var editingProductId: Int? = nil
    @Published var showEditSheet = false
    
    @Published var customName = ""
    @Published var customCalories = ""
    @Published var customProteins = ""
    @Published var customFats = ""
    @Published var customCarbs = ""
    
    // MARK: - Підготовка до редагування
    func prepareForEditing(_ product: ProductDTO) {
        editingProductId = product.id
        customName = product.name
        customCalories = String(format: "%.1f", product.calories).replacingOccurrences(of: ".", with: ",")
        customProteins = String(format: "%.1f", product.proteins).replacingOccurrences(of: ".", with: ",")
        customFats = String(format: "%.1f", product.fats).replacingOccurrences(of: ".", with: ",")
        customCarbs = String(format: "%.1f", product.carbs).replacingOccurrences(of: ".", with: ",")
        errorMessage = nil
    }
    
    func clearForm() {
        editingProductId = nil
        customName = ""
        customCalories = ""
        customProteins = ""
        customFats = ""
        customCarbs = ""
        errorMessage = nil
    }
    
    // MARK: - Завантаження початкового списку
    func loadInitialProducts() async {
        isLoading = true
        errorMessage = nil
        do { self.searchResults = try await CatalogRepository.shared.getProducts() }
        catch { errorMessage = "Не вдалося завантажити список продуктів." }
        isLoading = false
    }
    
    // MARK: - Пошук
    func search() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            await loadInitialProducts()
            return
        }
        isLoading = true
        errorMessage = nil
        do { searchResults = try await CatalogService.shared.searchProducts(query: searchQuery) }
        catch { errorMessage = "Помилка пошуку. Спробуйте ще раз." }
        isLoading = false
    }
    
    // MARK: - Створення АБО Оновлення власної страви
    func saveCustomProduct() async -> Bool {
        errorMessage = nil
        
        guard customName.isValidName else {
            errorMessage = "Некоректна назва (2-50 літер, без цифр)"
            return false
        }
        guard customCalories.isValidCalories else {
            errorMessage = "Калорії мають бути від 0 до 1000 ккал/100г"
            return false
        }
        guard customProteins.isValidMacro else {
            errorMessage = "Білки мають бути від 0 до 100 г"
            return false
        }
        guard customFats.isValidMacro else {
            errorMessage = "Жири мають бути від 0 до 100 г"
            return false
        }
        guard customCarbs.isValidMacro else {
            errorMessage = "Вуглеводи мають бути від 0 до 100 г"
            return false
        }
        
        let cal = customCalories.toDouble() ?? 0.0
        let prot = customProteins.toDouble() ?? 0.0
        let fats = customFats.toDouble() ?? 0.0
        let carbs = customCarbs.toDouble() ?? 0.0
        
        isLoading = true
        do {
            if let id = editingProductId {
                let currentUserId = AuthManager.shared.currentUserId ?? 0
                let updatedProduct = ProductDTO(id: id, name: customName, calories: cal, proteins: prot, carbs: carbs, fats: fats, barcode: nil, isApproved: false, createdByUserId: currentUserId, isRejected: false)
                
                let result = try await CatalogRepository.shared.updateCustomProduct(updatedProduct)
                
                if let index = searchResults.firstIndex(where: { $0.id == id }) {
                    searchResults[index] = result
                }
            } else {
                let newProduct = try await CatalogService.shared.createCustomProduct(
                    name: customName, calories: cal, proteins: prot, fats: fats, carbs: carbs
                )
                searchResults.insert(newProduct, at: 0)
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Помилка збереження: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Додавання у щоденник
    func addSelectedProductToDiary(mealType: String, date: Date) async -> Bool {
        errorMessage = nil
        
        guard portionGramsStr.isValidPortion else {
            errorMessage = "Введіть порцію від 1 до 3000 грамів."
            return false
        }
        
        guard let product = selectedProduct,
              let amount = portionGramsStr.toDouble(), amount > 0 else {
            errorMessage = "Введіть коректну вагу порції."
            return false
        }
        
        isLoading = true
        do {
            try await DiaryService.shared.addProductToDiary(product: product, amount: amount, mealType: mealType, date: date)
            isLoading = false
            return true
        } catch {
            errorMessage = "Не вдалося додати продукт у щоденник."
            isLoading = false
            return false
        }
    }
    
    // MARK: - Видалення
    func deleteMyProduct(id: Int) async {
        isLoading = true
        do {
            try await CatalogService.shared.deleteProduct(productId: id)
            searchResults.removeAll { $0.id == id }
        } catch {
            errorMessage = "Не вдалося видалити власну страву."
        }
        isLoading = false
    }
}
