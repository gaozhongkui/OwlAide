import HealthKit
import Foundation
import Combine

/// HealthKit 健康数据集成：血压、心率、步数
/// 完全本地，免费，不需要服务器
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    @Published var systolicBP: Double?       // 收缩压（高压）
    @Published var diastolicBP: Double?      // 舒张压（低压）
    @Published var heartRate: Double?        // 心率
    @Published var stepCount: Int?           // 今日步数
    @Published var isAuthorized = false

    // 需要读取的数据类型
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!
    ]

    // MARK: - 权限

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            await MainActor.run { isAuthorized = true }
            // 授权后立即拉取数据
            await fetchLatestBloodPressure()
            await fetchHeartRate()
            await fetchStepCount()
        } catch {
            print("HealthKit 授权失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 血压

    func fetchLatestBloodPressure() async {
        let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!

        let systolic = await fetchLatestValue(for: systolicType, unit: HKUnit.millimeterOfMercury())
        let diastolic = await fetchLatestValue(for: diastolicType, unit: HKUnit.millimeterOfMercury())

        await MainActor.run {
            self.systolicBP = systolic
            self.diastolicBP = diastolic
        }
    }

    // MARK: - 心率

    func fetchHeartRate() async {
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let bpm = HKUnit(from: "count/min")

        let value = await fetchLatestValue(for: hrType, unit: bpm)
        await MainActor.run {
            self.heartRate = value
        }
    }

    // MARK: - 步数

    func fetchStepCount() async {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        let value = await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                if let sum = result?.sumQuantity() {
                    continuation.resume(returning: sum.doubleValue(for: HKUnit.count()))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }

        await MainActor.run {
            if let v = value { stepCount = Int(v) }
        }
    }

    // MARK: - 通用查询

    private func fetchLatestValue(for type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    continuation.resume(returning: sample.quantity.doubleValue(for: unit))
                } else {
                    continuation.resume(returning: nil)
                }
            }
            store.execute(query)
        }
    }
}
