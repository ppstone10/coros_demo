import SwiftUI

@main
struct IOSDemoApp: App {
    @StateObject private var languageStore = AppLanguageStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageStore)
                .environment(\.locale, Locale(identifier: languageStore.current.rawValue))
        }
    }
}
