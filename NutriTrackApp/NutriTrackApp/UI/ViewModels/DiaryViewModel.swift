import Foundation
import Combine

@MainActor
class DiaryViewModel: ObservableObject {
    
    // MARK: - Дані для UI
    @Published var selectedDate: Date = Date()
    @Published var mealSections: [MealSectionUI] = []
    
    // MARK: - Стан інтерфейсу
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
    
    // MARK: - Завантаження даних (Вимога 2.4)
    func loadDiary() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.mealSections = try await DiaryService.shared.getDiary(for: selectedDate)
        } catch {
            errorMessage = "Не вдалося завантажити щоденник."
        }
        
        isLoading = false
    }
    
    // MARK: - Керування датами
    func changeDate(byDays days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            Task {
                await loadDiary()
            }
        }
    }
    
    // MARK: - Видалення продукту
    func deleteProduct(consumedId: Int) async {
        do {
            try await DiaryService.shared.deleteConsumedProduct(id: consumedId)
            await loadDiary()
        } catch {
            errorMessage = "Помилка при видаленні."
        }
    }
}
