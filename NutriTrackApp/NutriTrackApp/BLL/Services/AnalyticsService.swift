import Foundation

struct WeightChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

struct CalorieChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
}

class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}
    
    // MARK: - Динаміка ваги
    func getWeightTrend(days: Int) async throws -> [WeightChartDataPoint] {
        guard let userId = AuthManager.shared.currentUserId else { return [] }
        
        let userLogs = try await TrackingRepository.shared.getMeasurementLogs(userId: userId)
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return [] }
        
        let filteredLogs = userLogs.filter { $0.date >= startDate }
        
        var dailyWeights: [Date: Double] = [:]
        for log in filteredLogs {
            let startOfDay = calendar.startOfDay(for: log.date)
            dailyWeights[startOfDay] = log.weightKg
        }
        
        return dailyWeights
            .map { WeightChartDataPoint(date: $0.key, weight: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Споживання калорій 
    func getCalorieTrend(days: Int) async throws -> [CalorieChartDataPoint] {
        guard let userId = AuthManager.shared.currentUserId else { return [] }
        
        let diaryEntries = try await TrackingRepository.shared.getDiaryEntries(userId: userId)
        let allProducts = try await CatalogRepository.shared.getProducts()
        
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: now) else { return [] }
        
        let recentEntries = diaryEntries.filter { $0.date >= startDate }
        var dailyCalories: [Date: Double] = [:]
        
        for entry in recentEntries {
            guard let entryId = entry.id else { continue }
            let startOfDay = calendar.startOfDay(for: entry.date)
            
            let consumedHere = try await TrackingRepository.shared.getConsumedProducts(diaryEntryId: entryId)
            
            var dayTotal: Double = 0
            for consumed in consumedHere {
                if let product = allProducts.first(where: { $0.id == consumed.productId }) {
                    let nutrition = PortionCalculator.shared.calculateNutrition(for: product, weightGrams: consumed.amount)
                    dayTotal += nutrition.calories
                }
            }
            dailyCalories[startOfDay, default: 0] += dayTotal
        }
        
        return dailyCalories
            .map { CalorieChartDataPoint(date: $0.key, calories: $0.value) }
            .sorted { $0.date < $1.date }
    }
}
