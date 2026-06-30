import Foundation
import CoreLocation

/// 定位服务：获取当前位置用于紧急呼救
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// 请求定位权限并获取当前位置
    func requestCurrentLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        authorizationStatus = status

        // 已拒绝或受限，直接返回 nil
        if status == .denied || status == .restricted {
            return nil
        }

        // 需要先请求权限
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // 等待权限回调，最多 5 秒
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if manager.authorizationStatus != .authorizedWhenInUse && manager.authorizationStatus != .authorizedAlways {
                return nil
            }
        }

        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    /// 格式化为可读的地址描述
    func formattedLocation() async -> String {
        guard let location = await requestCurrentLocation() else {
            return "位置获取失败"
        }
        lastLocation = location
        return "纬度:\(String(format: "%.4f", location.coordinate.latitude)) 经度:\(String(format: "%.4f", location.coordinate.longitude))"
    }

    /// 生成紧急求救文本（含位置）
    func emergencyMessage() async -> String {
        let locationStr = await formattedLocation()
        return """
        🆘 紧急呼救
        位置：\(locationStr)
        时间：\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium))
        请尽快联系！
        """
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationContinuation?.resume(returning: locations.last)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
