import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    var isHealthDataAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws -> Bool {
        guard isHealthDataAvailable else { return false }
        
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return false
        }
        
        let typesToRead: Set<HKObjectType> = [stepsType, energyType]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
    
    func fetchSteps(for date: Date) async throws -> Double {
        return try await fetchQuantity(for: .stepCount, unit: HKUnit.count(), date: date)
    }
    
    func fetchActiveEnergy(for date: Date) async throws -> Double {
        return try await fetchQuantity(for: .activeEnergyBurned, unit: HKUnit.kilocalorie(), date: date)
    }
    
    private func fetchQuantity(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, date: Date) async throws -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw NSError(domain: "HealthKit", code: 404, userInfo: [NSLocalizedDescriptionKey: "Тип даних не знайдено"])
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else {
            return 0.0
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let total = result?.sumQuantity()?.doubleValue(for: unit) ?? 0.0
                continuation.resume(returning: total)
            }
            healthStore.execute(query)
        }
    }
}
