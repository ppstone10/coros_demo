import SwiftUI
import UIKit
import Shared

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
}

final class AppLanguageStore: ObservableObject {
    static let shared = AppLanguageStore()
    private static let preferenceKey = "app_language"

    @Published private(set) var current: AppLanguage

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.preferenceKey)
        current = AppLanguage(rawValue: stored ?? "") ?? .simplifiedChinese
    }

    func select(_ language: AppLanguage) {
        guard current != language else { return }
        current = language
        UserDefaults.standard.set(language.rawValue, forKey: Self.preferenceKey)
    }

    var localizedBundle: Bundle {
        guard let path = Bundle.main.path(forResource: current.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}

func appLocalized(_ key: String) -> String {
    AppLanguageStore.shared.localizedBundle.localizedString(forKey: key, value: key, table: nil)
}

func localizedAuthMessage(_ message: String?) -> String? {
    guard let message, !message.isEmpty else { return message }
    guard message.hasPrefix("auth_") else { return message }
    return appLocalized(message)
}

func countryDisplayName(_ code: String) -> String {
    switch code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
    case "US": return appLocalized("common_united_states")
    case "GB", "UK": return appLocalized("common_united_kingdom")
    case "JP": return appLocalized("common_japan")
    default: return appLocalized("common_china")
    }
}

struct LanguageSelectionButton: View {
    @EnvironmentObject private var languageStore: AppLanguageStore
    @State private var showsDialog = false

    var body: some View {
        Button { showsDialog = true } label: {
            Image(systemName: "globe")
                .font(.system(size: 23, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(appLocalized("language_switch"))
        .confirmationDialog(appLocalized("language_select_title"), isPresented: $showsDialog, titleVisibility: .visible) {
            Button(languageLabel(.simplifiedChinese)) { languageStore.select(.simplifiedChinese) }
            Button(languageLabel(.english)) { languageStore.select(.english) }
            Button(appLocalized("common_cancel"), role: .cancel) {}
        }
    }

    private func languageLabel(_ language: AppLanguage) -> String {
        let label = language == .simplifiedChinese ? appLocalized("language_chinese") : appLocalized("language_english")
        return languageStore.current == language ? "✓ \(label)" : label
    }
}

enum AppColors {
    enum Core {
        static let black = Color.black
        static let white = Color.white
        static let clear = Color.clear
        static let snackbar = Color.black.opacity(0.85)
        static let overlayStrong = Color.black.opacity(0.78)
        static let overlayLoading = Color.black.opacity(0.72)
        static let overlayMedium = Color.black.opacity(0.62)
        static let overlaySoft = Color.black.opacity(0.55)
    }

    enum Auth {
        static let entranceBackground = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
        static let inputText = Color(red: 216 / 255, green: 216 / 255, blue: 221 / 255)
        static let sheet = Color(red: 27 / 255, green: 27 / 255, blue: 29 / 255)
        static let dialog = Color(red: 34 / 255, green: 34 / 255, blue: 36 / 255)
        static let loading = Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255)
        static let inputBorder = Color(red: 58 / 255, green: 58 / 255, blue: 61 / 255)
        static let avatarBorder = Color(red: 48 / 255, green: 48 / 255, blue: 54 / 255)
        static let termsSheet = Color(red: 26 / 255, green: 26 / 255, blue: 27 / 255)
        static let buttonOverlay = Color.white.opacity(0.26)
        static let primaryText = Color.white.opacity(0.78)
        static let placeholderText = Color.white.opacity(0.55)
        static let checkboxBorder = Color.white.opacity(0.82)
        static let disabledText = Color.white.opacity(0.42)
    }

    enum Health {
        static let page = Color.black
        static let card = Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255)
        static let muted = Color(red: 119 / 255, green: 119 / 255, blue: 119 / 255)
        static let gauge = Color(red: 1, green: 183 / 255, blue: 53 / 255)
        static let steps = Color(red: 0, green: 223 / 255, blue: 123 / 255)
        static let calories = Color(red: 1, green: 201 / 255, blue: 40 / 255)
        static let active = Color(red: 215 / 255, green: 43 / 255, blue: 204 / 255)
        static let action = Color(red: 240 / 255, green: 0, blue: 60 / 255)
        static let addAction = Color(red: 0, green: 223 / 255, blue: 123 / 255)
        static let risk = Color(red: 1, green: 163 / 255, blue: 74 / 255)
        static let divider = Color(red: 48 / 255, green: 48 / 255, blue: 48 / 255)
        static let editText = Color(red: 221 / 255, green: 221 / 255, blue: 221 / 255)
        static let date = Color(red: 140 / 255, green: 140 / 255, blue: 140 / 255)
        static let metricUnit = Color(red: 137 / 255, green: 137 / 255, blue: 137 / 255)
        static let cardTitle = Color(red: 232 / 255, green: 232 / 255, blue: 232 / 255)
        static let chevron = Color(red: 102 / 255, green: 102 / 255, blue: 102 / 255)
        static let warning = Color(red: 255 / 255, green: 75 / 255, blue: 85 / 255)
        static let editorTitle = Color(red: 236 / 255, green: 236 / 255, blue: 236 / 255)
        static let removeAction = Color(red: 239 / 255, green: 52 / 255, blue: 63 / 255)
        static let placeholder = Color(red: 187 / 255, green: 187 / 255, blue: 187 / 255)
        static let visualGreen = steps
        static let visualYellow = calories
        static let visualOrange = Color(red: 1, green: 159 / 255, blue: 48 / 255)
        static let visualPurple = Color(red: 183 / 255, green: 105 / 255, blue: 1)
        static let visualBlue = Color(red: 66 / 255, green: 165 / 255, blue: 245 / 255)
        static let visualCyan = Color(red: 45 / 255, green: 205 / 255, blue: 211 / 255)
        static let visualPink = Color(red: 232 / 255, green: 45 / 255, blue: 138 / 255)
        static let visualDeepBlue = Color(red: 49 / 255, green: 86 / 255, blue: 184 / 255)
        static let stressLow = Color(red: 68 / 255, green: 154 / 255, blue: 250 / 255)
        static let stressGood = Color(red: 170 / 255, green: 219 / 255, blue: 55 / 255)
        static let visualBar = Color(red: 98 / 255, green: 98 / 255, blue: 98 / 255)
        static let rangeTrack = Color(red: 69 / 255, green: 69 / 255, blue: 69 / 255)
        static let gaugeTrack = Color(red: 51 / 255, green: 51 / 255, blue: 51 / 255)
        static let activityTile = Color(red: 34 / 255, green: 60 / 255, blue: 50 / 255)
    }

    enum Account {
        static let card = Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255)
        static let muted = Color(red: 138 / 255, green: 138 / 255, blue: 142 / 255)
        static let complete = Color(red: 25 / 255, green: 200 / 255, blue: 117 / 255)
        static let incomplete = Color(red: 1, green: 183 / 255, blue: 53 / 255)
        static let destructive = Color(red: 1, green: 64 / 255, blue: 83 / 255)
        static let divider = Color(red: 43 / 255, green: 43 / 255, blue: 45 / 255)
        static let avatarFallback = Color(red: 48 / 255, green: 48 / 255, blue: 52 / 255)
        static let value = Color(red: 216 / 255, green: 216 / 255, blue: 220 / 255)
        static let saveDisabled = Color(red: 95 / 255, green: 0, blue: 28 / 255)
        static let sheet = Color(red: 26 / 255, green: 26 / 255, blue: 27 / 255)
    }

    enum Profile {
        static let description = Color(red: 232 / 255, green: 232 / 255, blue: 236 / 255)
        static let control = Color(red: 27 / 255, green: 27 / 255, blue: 29 / 255)
        static let value = Color.white.opacity(0.78)
    }

    enum Navigation {
        static let bar = Color(red: 26 / 255, green: 26 / 255, blue: 28 / 255).opacity(0.95)
        static let unselected = Color(red: 133 / 255, green: 134 / 255, blue: 138 / 255)
    }
}

enum AppTypography {
    static let caption: CGFloat = 11
    static let supporting: CGFloat = 12
    static let label: CGFloat = 13
    static let action: CGFloat = 14
    static let editorRow: CGFloat = 15
    static let cardTitle: CGFloat = 16
    static let sectionTitle: CGFloat = 19
    static let heroTitle: CGFloat = 28
}

enum AppSpacing {
    static let xSmall: CGFloat = 5
    static let small: CGFloat = 8
    static let medium: CGFloat = 10
    static let captionBottom: CGFloat = 11
    static let contentVertical: CGFloat = 12
    static let labelVertical: CGFloat = 14
    static let cardContent: CGFloat = 15
    static let screen: CGFloat = 16
    static let large: CGFloat = 18
    static let page: CGFloat = 20
    static let section: CGFloat = 24
    static let actionHorizontal: CGFloat = 28
}

enum AppImages {
    enum Profile {
        static let camera = "icon_camera"
        static let next = "right_more"
        static let edit = "icon_edit"
    }

    enum Health {
        static let calendar = "icon_calendar"
        static let device = "icon_device_sportting"
        static let steps = "steps_icon"
        static let calories = "icon_calories"
        static let active = "sport_time_icon"
        static let add = "data_screen_edit_add"
        static let remove = "delete"
        static let choiceChevron = "right_more"
        static let choiceCheck = "ic_profile_check"
        static let activityMap = "health_activity_map"
        static let todayHeader = "health_today_header"
        static let todayRunner = "health_today_runner"
        static let bodyMaleFrontBase = "health_body_male_front_base"
        static let bodyMaleBackBase = "health_body_male_back_base"
        static let bodyMuscleRegions: [String: String] = [
            "shoulders_front": "health_body_shoulders_front",
            "shoulders_back": "health_body_shoulders_back",
            "chest_front": "health_body_chest_front",
            "trapezius_back": "health_body_back_trapezius",
            "latissimus_back": "health_body_back_latissimus",
            "erector_spinae_back": "health_body_back_erector_spinae",
            "biceps_front": "health_body_biceps_front",
            "triceps_back": "health_body_triceps_back",
            "abdominals_front": "health_body_abdominals_front",
            "glutes_back": "health_body_glutes_back",
            "quadriceps_front": "health_body_quadriceps_front",
            "hamstrings_back": "health_body_hamstrings_back",
            "calves_front": "health_body_calves_front",
            "calves_back": "health_body_calves_back"
        ]
        static let recoveryStatus = "health_recovery_status"
        static let weeklyPlan = "icon_small_plan"
        static let todayActivity = "icon_small_training_effect"
        static let trainingLoad = "icon_small_training_load"
        static let trainingAssessment = "icon_small_training_effect"
        static let recovery = "health_recovery_time"
        static let runningAbility = "icon_small_running_ability"
        static let cyclingAbility = "icon_small_cycling"
        static let heartRate = "icon_small_heart_rate"
        static let stress = "icon_small_stress"
        static let sleep = "icon_small_sleep"
        static let hrv = "icon_small_sleep_hrv"
        static let restingHeartRate = "icon_small_rhr"
        static let healthCheck = "icon_small_health_detection"
        static let body = "icon_small_body"
    }

    enum Navigation {
        static let fitness = ("icon_tab_home", "icon_tab_home_selected")
        static let records = ("icon_tab_workout_list", "icon_tab_workout_list_selected")
        static let explore = ("icon_tab_explore", "icon_tab_explore_selected")
        static let me = ("icon_tab_me", "icon_tab_me_selected")
    }
}

enum ProfileImageStore {
    /// 头像缩放后的最大边长（像素）。控制上传体积。
    private static let maxDimension: CGFloat = 512

    /// 头像在 mock server 的相对路径（MSRV-015：真实图片文件 + URL 展示）。
    static func avatarServerPath(userId: String) -> String {
        "/api/avatar/\(userId)"
    }

    /// 当前账号头像本地文件：Documents/avatar_current.jpg（MSRV-015 即时显示）。
    private static var currentURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("avatar_current.jpg")
    }

    private static func currentImage() -> UIImage? {
        let url = currentURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    private static func writeCurrent(_ data: Data) {
        try? data.write(to: currentURL)
    }

    /// 删除当前头像本地文件（注销账号）。
    static func deleteCache() {
        try? FileManager.default.removeItem(at: currentURL)
    }

    /// 上传头像：缩放 → JPEG → PUT 到 mock server；成功后覆盖当前头像本地文件；返回相对路径；失败返回 nil。
    static func save(_ data: Data, userId: String) async -> String? {
        let jpegData = downscaledJPEG(from: data) ?? data
        let path = avatarServerPath(userId: userId)
        guard let url = URL(string: "\(IosMockServerConfig.shared.baseUrl)\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue(IosMockServerConfig.shared.deviceId, forHTTPHeaderField: "X-Device-Id")
        request.httpBody = jpegData
        request.timeoutInterval = 5
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                writeCurrent(jpegData)
                return path
            }
            return nil
        } catch {
            return nil
        }
    }

    /// 登录/切换账号后刷新当前头像：清除旧的，再按 avatarUri 从服务器拉取覆盖。
    static func refreshFromServer(avatarUri: String?) {
        clearCurrent()
        guard let avatarUri, avatarUri.hasPrefix("/api/avatar/"),
              let url = URL(string: "\(IosMockServerConfig.shared.baseUrl)\(avatarUri)") else { return }
        URLSession.shared.dataTask(with: url) { data, response, _ in
            if let data, let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                writeCurrent(data)
            }
        }.resume()
    }

    private static func clearCurrent() {
        try? FileManager.default.removeItem(at: currentURL)
    }

    private static func downscaledJPEG(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else {
            return image.jpegData(compressionQuality: 0.85)
        }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return scaled.jpegData(compressionQuality: 0.85)
    }

    /// 从 avatarUri 解析 UIImage：服务器相对路径 → 当前头像本地文件优先，未命中再下载并覆盖；旧格式回退。
    static func image(at key: String?) -> UIImage? {
        guard let key, !key.isEmpty else { return nil }
        if key.hasPrefix("/api/avatar/") {
            if let cached = currentImage() {
                return cached
            }
            guard let url = URL(string: "\(IosMockServerConfig.shared.baseUrl)\(key)") else { return nil }
            let semaphore = DispatchSemaphore(value: 0)
            var result: UIImage? = nil
            URLSession.shared.dataTask(with: url) { data, response, _ in
                if let data, let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    writeCurrent(data)
                    result = UIImage(data: data)
                }
                semaphore.signal()
            }.resume()
            _ = semaphore.wait(timeout: .now() + 5)
            return result
        }
        if key.hasPrefix("data:image") {
            if let data = dataURIData(key) {
                return UIImage(data: data)
            }
        }
        if key.hasPrefix("profile_avatar_data_") {
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return UIImage(data: data)
        }
        return UIImage(contentsOfFile: key)
    }

    private static func dataURIData(_ dataUri: String) -> Data? {
        guard let comma = dataUri.firstIndex(of: ",") else { return nil }
        let base64 = String(dataUri[dataUri.index(after: comma)...])
        return Data(base64Encoded: base64)
    }
}

#Preview("Language selection button") {
    LanguageSelectionButton()
        .environmentObject(AppLanguageStore.shared)
        .padding(24)
        .background(AppColors.Core.black)
        .preferredColorScheme(.dark)
}
