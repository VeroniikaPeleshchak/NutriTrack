import Foundation
import Combine

@MainActor
class AdminViewModel: ObservableObject {
    
    // MARK: - Дані для UI (Статистика)
    @Published var stats: AdminStatsDTO? = nil
    
    // MARK: - Дані для UI (Списки)
    @Published var pendingRequests: [ProductDTO] = []
    @Published var globalProducts: [ProductDTO] = []
    
    @Published var filteredGlobalProducts: [ProductDTO] = []
    @Published var searchQuery: String = "" {
        didSet {
            filterProducts()
        }
    }
    
    // MARK: - Стан інтерфейсу
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Дані для форми Додавання/Редагування
    @Published var showEditSheet = false
    @Published var editingProduct: ProductDTO? = nil
    
    @Published var productName = ""
    @Published var productCalories = ""
    @Published var productProteins = ""
    @Published var productFats = ""
    @Published var productCarbs = ""
    
    // MARK: - Завантаження Головної панелі
    func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let fetchedStats = AdminService.shared.getDashboardStats()
            async let fetchedPending = AdminService.shared.getPendingRequests()
            
            self.stats = try await fetchedStats
            self.pendingRequests = try await fetchedPending
        } catch {
            errorMessage = "Не вдалося завантажити дані панелі адміністратора."
        }
        
        isLoading = false
    }
    
    // MARK: - Завантаження всієї бази
    func loadGlobalProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.globalProducts = try await AdminService.shared.getAllProducts()
            filterProducts()
        } catch {
            errorMessage = "Не вдалося завантажити базу продуктів."
        }
        
        isLoading = false
    }
    
    private func filterProducts() {
        if searchQuery.isEmpty {
            filteredGlobalProducts = globalProducts
        } else {
            filteredGlobalProducts = globalProducts.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }
    }
    
    // MARK: - Модерація
    func approveProduct(id: Int) async {
        isLoading = true
        do {
            try await AdminService.shared.approveRequest(productId: id)
            pendingRequests.removeAll { $0.id == id }
            self.stats = try? await AdminService.shared.getDashboardStats()
        } catch { errorMessage = "Помилка при схваленні." }
        isLoading = false
    }
    
    func rejectProduct(id: Int) async {
        isLoading = true
        do {
            try await AdminService.shared.rejectRequest(productId: id)
            pendingRequests.removeAll { $0.id == id }
            self.stats = try? await AdminService.shared.getDashboardStats()
        } catch { errorMessage = "Помилка при відхиленні." }
        isLoading = false
    }
    
    func deleteGlobalProduct(id: Int) async {
        isLoading = true
        do {
            try await AdminService.shared.deleteProduct(productId: id)
            globalProducts.removeAll { $0.id == id }
            filterProducts()
            self.stats = try? await AdminService.shared.getDashboardStats()
        } catch { errorMessage = "Помилка при видаленні." }
        isLoading = false
    }
    
    // MARK: - Робота з формою (Додавання / Редагування)
    func openAddSheet() {
        editingProduct = nil
        productName = ""
        productCalories = ""
        productProteins = ""
        productFats = ""
        productCarbs = ""
        errorMessage = nil
        showEditSheet = true
    }
    
    func openEditSheet(for product: ProductDTO) {
        editingProduct = product
        productName = product.name
        productCalories = String(format: "%.1f", product.calories).replacingOccurrences(of: ".", with: ",")
        productProteins = String(format: "%.1f", product.proteins).replacingOccurrences(of: ".", with: ",")
        productFats = String(format: "%.1f", product.fats).replacingOccurrences(of: ".", with: ",")
        productCarbs = String(format: "%.1f", product.carbs).replacingOccurrences(of: ".", with: ",")
        errorMessage = nil
        showEditSheet = true
    }
    
    // MARK: - Збереження з валідацією[cite: 27, 29]
    func saveProduct() async -> Bool {
        errorMessage = nil
        
        guard productName.isValidName else {
            errorMessage = "Некоректна назва (2-50 літер, без цифр)"
            return false
        }
        guard productCalories.isValidCalories else {
            errorMessage = "Калорії мають бути від 0 до 1000 ккал/100г"
            return false
        }
        guard productProteins.isValidMacro else {
            errorMessage = "Білки мають бути від 0 до 100 г"
            return false
        }
        guard productFats.isValidMacro else {
            errorMessage = "Жири мають бути від 0 до 100 г"
            return false
        }
        guard productCarbs.isValidMacro else {
            errorMessage = "Вуглеводи мають бути від 0 до 100 г"
            return false
        }
        
        let cal = productCalories.toDouble() ?? 0.0
        let prot = productProteins.toDouble() ?? 0.0
        let fats = productFats.toDouble() ?? 0.0
        let carbs = productCarbs.toDouble() ?? 0.0
        
        isLoading = true
        
        if let existing = editingProduct {
            let updated = ProductDTO(id: existing.id, name: productName, calories: cal, proteins: prot, carbs: carbs, fats: fats, barcode: existing.barcode, isApproved: existing.isApproved, createdByUserId: existing.createdByUserId)
            do {
                try await AdminService.shared.editProduct(product: updated)
                await loadGlobalProducts()
                self.stats = try? await AdminService.shared.getDashboardStats()
                isLoading = false
                return true
            } catch {
                errorMessage = "Не вдалося оновити продукт."
                isLoading = false
                return false
            }
        } else {
            let currentUserId = AuthManager.shared.currentUserId ?? 0
            let newProduct = ProductDTO(id: nil, name: productName, calories: cal, proteins: prot, carbs: carbs, fats: fats, barcode: nil, isApproved: true, createdByUserId: currentUserId)
            do {
                try await AdminService.shared.addProduct(product: newProduct)
                await loadGlobalProducts()
                self.stats = try? await AdminService.shared.getDashboardStats()
                isLoading = false
                return true
            } catch {
                errorMessage = "Не вдалося створити продукт."
                isLoading = false
                return false
            }
        }
    }
}
