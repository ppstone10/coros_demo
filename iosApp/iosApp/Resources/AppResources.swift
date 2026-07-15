import SwiftUI
import UIKit

enum AppText {
    enum Common {
        static let back = "‹"
        static let save = "保存"
        static let cancel = "取消"
        static let confirm = "确认"
        static let notSet = "未设置"
    }

    enum Navigation {
        static let fitness = "体能"
        static let records = "记录"
        static let explore = "探索"
        static let me = "我"

        static func unavailable(_ name: String) -> String { "\(name) 功能将在后续版本开放" }
    }

    enum Health {
        static let today = "今天"
        static let date = "7月14日 星期二"
        static let editCards = "编辑卡片"
        static let manageOrder = "管理卡片顺序（最少展示3项）"
        static let minimumCards = "最少展示三项日常数据"
        static let moreData = "更多日常数据"
        static let restoreDefaults = "恢复默认数据"
        static let steps = "步"
        static let calories = "Kcal"
        static let minutes = "Min"

        static func pending(_ title: String) -> String { "\(title)功能后续实现" }
    }

    enum Profile {
        static let completionTitle = "完善个人信息"
        static let completionDescription = "以下信息可以帮助我们对体育科学做出更准确的预测，请仔细填写。"
        static let personalInfo = "个人信息"
        static let username = "用户名"
        static let birthDate = "出生日期"
        static let height = "身高"
        static let weight = "体重"
        static let unit = "公英制"
        static let phone = "手机"
        static let country = "国家与地区"
        static let gender = "性别"
    }

    enum Account {
        static let my = "我"
        static let incomplete = "待完善"
        static let complete = "已完善"
        static let personalInfo = "个人信息"
        static let accountSection = "账号"
        static let loginAccount = "登录账号"
        static let logout = "退出登录"
        static let delete = "注销账户"
        static let deleteConfirmation = "是否确认注销账号"
        static let defaultUser = "COROS 用户"
    }
}

enum AppColors {
    enum Core {
        static let black = Color.black
        static let white = Color.white
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
    }

    enum Account {
        static let card = Color(red: 25 / 255, green: 25 / 255, blue: 25 / 255)
        static let muted = Color(red: 138 / 255, green: 138 / 255, blue: 142 / 255)
        static let complete = Color(red: 25 / 255, green: 200 / 255, blue: 117 / 255)
        static let incomplete = Color(red: 1, green: 183 / 255, blue: 53 / 255)
        static let destructive = Color(red: 1, green: 64 / 255, blue: 83 / 255)
        static let divider = Color(red: 43 / 255, green: 43 / 255, blue: 45 / 255)
    }

    enum Navigation {
        static let bar = Color(red: 26 / 255, green: 26 / 255, blue: 28 / 255).opacity(0.95)
        static let unselected = Color(red: 133 / 255, green: 134 / 255, blue: 138 / 255)
    }
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
        static let weeklyPlan = "icon_small_plan"
        static let trainingLoad = "icon_small_training_load"
        static let trainingAssessment = "icon_small_training_effect"
        static let recovery = "icon_recovery_sports"
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
    static func save(_ data: Data) -> String? {
        guard let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("profile-avatar.jpg")
            try data.write(to: url, options: .atomic)
            return url.path
        } catch {
            return nil
        }
    }

    static func image(at path: String?) -> UIImage? {
        guard let path, !path.isEmpty else { return nil }
        return UIImage(contentsOfFile: path)
    }
}
