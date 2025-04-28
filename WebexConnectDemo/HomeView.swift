//
//  HomeView.swift
//  WebexConnectDemo
//

import SwiftUI
import WebexConnectCore

/// Environment key to control tab bar visibility
private struct TabBarVisibilityKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

extension EnvironmentValues {
    /// Environment variable to hide or show the tab bar
    var tabBarHidden: Binding<Bool> {
        get { self[TabBarVisibilityKey.self] }
        set { self[TabBarVisibilityKey.self] = newValue }
    }
}

/// `HomeView` serves as the main dashboard screen after user login.
///
/// It provides a tab-based interface with the following functionalities:
/// - Displays two main tabs: **Messaging** and **Notifications**.
/// - Allows dynamic switching between tabs programmatically via notifications.
/// - Shows unread message counts as a badge on the Messaging tab.
/// - Supports hiding and showing the tab bar based on the active view's needs.
/// - Configures the tab bar's appearance to match the app's design theme.
struct HomeView: View {
    private let webexConnect = WebexConnectProvider.instance
    private var userId: String = ""
    
    @State private var isUserSignedIn = true
    @State private var isTabBarHidden = false  // State to control tab bar visibility
    @State private var selectedTab: Int = 0    // State to track selected tab
    
    @StateObject private var viewModel = ThreadsViewModel()
    
    /// Initializes the dashboard view and configures the tab bar appearance
    init() {
        self.userId = webexConnect.deviceProfile?.userId ?? ""
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            /// Messaging Tab
            MessagingView(isUserSignedIn: $isUserSignedIn, userId: userId, selectedTab: $selectedTab, viewModel: viewModel)
                .tabItem {
                    Label("Messaging", systemImage: "message.fill")
                }
                .tag(0)
                .environmentObject(viewModel)
                .id(selectedTab)
            
            /// Notifications Tab
            NotificationsView(isUserSignedIn: $isUserSignedIn, userId: userId, selectedTab: $selectedTab)
                .tabItem {
                    Label("Notifications", systemImage: "megaphone")
                }
                .tag(1)
                .environmentObject(viewModel)
                .id(selectedTab)
        }
        .accentColor(.blue)
        .environment(\ .tabBarHidden, $isTabBarHidden)  // Pass tab bar visibility state
        .onChange(of: isTabBarHidden) { updateTabBarVisibility(hidden: $0) }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToMessaging"))) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToNotifications"))) { _ in
            selectedTab = 1
        }
    }
    
    /// Updates the visibility of the tab bar
    /// - Parameter hidden: Boolean value indicating if the tab bar should be hidden
    private func updateTabBarVisibility(hidden: Bool) {
        DispatchQueue.main.async {
            if let tabBarController = getTabBarController() {
                tabBarController.tabBar.isHidden = hidden
            }
        }
    }
    
    /// Retrieves the UITabBarController instance from the root view controller
    /// - Returns: An optional UITabBarController instance
    private func getTabBarController() -> UITabBarController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController as? UITabBarController
    }
}

#Preview {
    HomeView()
}
