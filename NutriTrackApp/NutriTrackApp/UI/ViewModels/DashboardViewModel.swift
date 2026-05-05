import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Дані дати
    @Published var selectedDate: Date = Date()
    
    @Published var calorieGoal: Double = 0
    @Published var proteinGoal: Double = 0
    @Published var carbGoal: Double = 0
    @Published var fatGoal: Double = 0
    
    @Published var consumedCalories: Double = 0
    @Published var consumedProtein: Double = 0
    @Published var consumedCarb: Double = 0
    @Published var consumedFat: Double = 0
    
    @Published var waterAmount: Int = 0
    @Published var steps: Int = 0
    @Published var burnedCalories: Double = 0
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var remainingCalories: Double {
        let remaining = calorieGoal - consumedCalories + burnedCalories
        return remaining > 0 ? remaining : 0
    }
    
    // MARK: - Форматування дати для UI
    var displayDateString: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Сьогодні"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Вчора"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Завтра"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM.yyyy"
            return formatter.string(from: selectedDate)
        }
    }
    
    // MARK: - Зміна дати
    func changeDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            Task {
                await loadDailyData()
            }
        }
    }
    
    func loadDailyData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = AuthManager.shared.currentUserId else { return }
            
            if let profile = AuthManager.shared.currentUserProfile {
                self.calorieGoal = profile.dailyCalorieGoal
                self.proteinGoal = profile.dailyProteinGoal
                self.carbGoal = profile.dailyCarbGoal
                self.fatGoal = profile.dailyFatGoal
            }
            
            if AuthManager.shared.currentUserProfile?.isAppleHealthSyncEnabled == true {
                try? await ActivityService.shared.syncWithHealthKit(for: selectedDate)
            }
            
            let allWaterLogs = try await TrackingRepository.shared.getWaterLogs(userId: userId)
            self.waterAmount = allWaterLogs
                .filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
                .reduce(0) { $0 + $1.amountMl }
            
            let allActivityLogs = try await TrackingRepository.shared.getActivityLogs(userId: userId)
            if let activity = allActivityLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) {
                self.steps = activity.steps
                self.burnedCalories = activity.burnedCalories
            } else {
                self.steps = 0
                self.burnedCalories = 0
            }
            
            let diarySections = try await DiaryService.shared.getDiary(for: selectedDate)
            calculateTotals(from: diarySections)
            
        } catch {
            errorMessage = "Помилка завантаження даних."
        }
        isLoading = false
    }
    
    // MARK: - Додавання води для вибраної дати
    func addWater(amount: Int) async {
        do {
            guard let userId = AuthManager.shared.currentUserId else { return }
            let newLog = WaterLogDTO(id: nil, userId: userId, date: selectedDate, amountMl: amount)
            try await TrackingRepository.shared.saveWaterLog(newLog)
            await loadDailyData()
        } catch {
            errorMessage = "Не вдалося додати воду."
        }
    }
    
    // MARK: - Видалення води для вибраної дати
    func removeLastWater() async {
        do {
            guard let userId = AuthManager.shared.currentUserId else { return }
            let allLogs = try await TrackingRepository.shared.getWaterLogs(userId: userId)
            let targetLogs = allLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            
            if let lastLog = targetLogs.last, let logId = lastLog.id {
                try await TrackingRepository.shared.deleteWaterLog(id: logId)
                await loadDailyData()
            }
        } catch {
            errorMessage = "Не вдалося видалити воду."
        }
    }
    
    private func calculateTotals(from sections: [MealSectionUI]) {
        var totalCals: Double = 0
        var totalProts: Double = 0
        var totalFats: Double = 0
        var totalCarbs: Double = 0
            
        for section in sections {
            for item in section.consumedItems {
                totalCals += item.totalCalories
                let nutrition = PortionCalculator.shared.calculateNutrition(for: item.product, weightGrams: item.amount)
                totalProts += nutrition.proteins
                totalFats += nutrition.fats
                totalCarbs += nutrition.carbs
            }
        }
            
        self.consumedCalories = totalCals.rounded()
        self.consumedProtein = totalProts.rounded()
        self.consumedFat = totalFats.rounded()
        self.consumedCarb = totalCarbs.rounded()
    }
}
