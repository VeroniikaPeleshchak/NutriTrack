import Foundation
import Combine

@MainActor
class AnalyticsViewModel: ObservableObject {
    
    @Published var weightData: [WeightChartDataPoint] = []
    @Published var calorieData: [CalorieChartDataPoint] = []
    @Published var dailyCalorieGoal: Double = 1800
    
    @Published var selectedPeriod: String = "Тиждень" {
        didSet {
            Task { await loadAnalytics() }
        }
    }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var weightChange: Double {
        guard weightData.count >= 2 else { return 0 }
        return (weightData.last?.weight ?? 0) - (weightData.first?.weight ?? 0)
    }
    
    var averageCalories: Double {
        guard !calorieData.isEmpty else { return 0 }
        let total = calorieData.reduce(0) { $0 + $1.calories }
        return total / Double(calorieData.count)
    }
    
    func loadAnalytics() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let profile = AuthManager.shared.currentUserProfile {
                self.dailyCalorieGoal = profile.dailyCalorieGoal
            }
            
            let days: Int
            switch selectedPeriod {
            case "Місяць": days = 30
            case "Рік": days = 365
            default: days = 7
            }
            
            async let fetchedWeight = AnalyticsService.shared.getWeightTrend(days: days)
            async let fetchedCalories = AnalyticsService.shared.getCalorieTrend(days: days)
            
            self.weightData = try await fetchedWeight
            self.calorieData = try await fetchedCalories
            
        } catch {
            errorMessage = "Не вдалося завантажити аналітику: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
