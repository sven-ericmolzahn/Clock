import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gear") }
            WorldClocksSettingsTab()
                .tabItem { Label("World Clocks", systemImage: "globe") }
        }
        .frame(width: 550, height: 500)
    }
}
