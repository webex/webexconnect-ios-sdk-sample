//
//  WebexConnectDemoApp.swift
//  WebexConnectDemo
//

import SwiftUI
import WebexConnectCore

/// Main entry point for the WebexConnectDemo application.
@main
struct WebexConnectDemo: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var deeplinkHandler = DeeplinkHandler()
    
    var body: some Scene {
        WindowGroup {
            contentView()
                .onOpenURL(perform: deeplinkHandler.handleDeepLink)
        }
    }
    
    /// Determines the content view based on the registration status.
    @ViewBuilder
    private func contentView() -> some View {
        if deeplinkHandler.isRegistered {
            HomeView()
        } else {
            LoginView()
        }
    }
}


