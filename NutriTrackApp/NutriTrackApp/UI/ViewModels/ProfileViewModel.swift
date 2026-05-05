import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var currentWeight: Double = 0.0
    @Published var height: Double = 0.0
    @Published var goalWeight: Double = 0.0
    
    @Published var waist: String = ""
    @Published var chest: String = ""
    @Published var hips: String = ""
    
    @Published var isHealthSyncEnabled: Bool = false
    @Published var isAdmin: Bool = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var exportedFileURL: URL?
    @Published var showExportShareSheet = false
    @Published var navigateToLogin = false
    @Published var showDeleteConfirmation = false
    
    func loadProfile() {
        if let user = AuthManager.shared.currentUser {
            self.name = user.name
            self.email = user.email
            self.isAdmin = user.role.lowercased() == "адмін" || user.role.lowercased() == "admin"
        }
        if let profile = AuthManager.shared.currentUserProfile {
            self.currentWeight = profile.currentWeight
            self.height = profile.height
            self.goalWeight = profile.goalWeight
            self.isHealthSyncEnabled = profile.isAppleHealthSyncEnabled
            
        }
        
        if let userId = AuthManager.shared.currentUserId {
            Task {
                do {
                    let logs = try await TrackingRepository.shared.getMeasurementLogs(userId: userId)
                    if let latest = logs.sorted(by: { $0.date > $1.date }).first {
                        if let w = latest.waistCm, w > 0 { self.waist = String(format: "%.1f", w).replacingOccurrences(of: ".", with: ",") }
                        if let c = latest.chestCm, c > 0 { self.chest = String(format: "%.1f", c).replacingOccurrences(of: ".", with: ",") }
                        if let h = latest.hipsCm, h > 0 { self.hips = String(format: "%.1f", h).replacingOccurrences(of: ".", with: ",") }
                    }
                } catch {
                    print("Не вдалося завантажити історію вимірів")
                }
            }
        }
    }
    
    func updateBodyMeasurements(newWeight: String) async -> Bool {
        errorMessage = nil
        
        guard newWeight.isValidWeight else {
            errorMessage = "Вага має бути від 20 до 300 кг"
            return false
        }
        
        if !waist.isEmpty && !waist.isValidMeasurement { errorMessage = "Талія: 30-300 см"; return false }
        if !chest.isEmpty && !chest.isValidMeasurement { errorMessage = "Груди: 30-300 см"; return false }
        if !hips.isEmpty && !hips.isValidMeasurement { errorMessage = "Стегна: 30-300 см"; return false }
        
        let weightValue = newWeight.toDouble() ?? currentWeight
        let waistValue = waist.toDouble() ?? 0.0
        let chestValue = chest.toDouble() ?? 0.0
        let hipsValue = hips.toDouble() ?? 0.0
        
        isLoading = true
        do {
            try await ProfileService.shared.updateMeasurements(
                weight: weightValue,
                waist: waistValue,
                chest: chestValue,
                hips: hipsValue
            )
            loadProfile()
            isLoading = false
            return true
        } catch {
            errorMessage = "Помилка оновлення"
            isLoading = false
            return false
        }
    }
    
    func exportData() async {
        isLoading = true
        errorMessage = nil
        do {
            let url = try await ExportService.shared.exportDiaryToCSV()
            self.exportedFileURL = url
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showExportShareSheet = true
            }
        } catch {
            errorMessage = "Помилка експорту"
        }
        isLoading = false
    }
    
    func toggleHealthSync(isOn: Bool) async {
        isLoading = true
        do {
            try await ProfileService.shared.toggleAppleHealthSync(isEnabled: isOn)
            self.isHealthSyncEnabled = isOn
        } catch { self.isHealthSyncEnabled = !isOn }
        isLoading = false
    }
    
    func logout() async {
        await AuthService.shared.logout()
        NotificationCenter.default.post(name: NSNotification.Name("Logout"), object: nil)
        navigateToLogin = true
    }
    
    func deleteAccount() async {
        isLoading = true
        do {
            try await AuthService.shared.deleteAccount()
            NotificationCenter.default.post(name: NSNotification.Name("Logout"), object: nil)
            navigateToLogin = true
        } catch { errorMessage = "Помилка видалення" }
        isLoading = false
    }
}
