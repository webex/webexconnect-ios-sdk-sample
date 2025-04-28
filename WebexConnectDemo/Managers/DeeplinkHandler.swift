//
//  DeeplinkHandler.swift
//  WebexConnectDemo
//
import Foundation
import WebexConnectCore

/// Manages WebexConnect registration status and deep link handling.
final class DeeplinkHandler: ObservableObject {
    @Published var isRegistered: Bool // Tracks if the user is registered
    private let webexConnect = WebexConnectProvider.instance
    
    
    /// WebexConnectSDK:  Initializes the WebexConnectManager and sets the initial registration status.
    init() {
        self.isRegistered = webexConnect.isRegistered
    }
    
    /// Handles deep link navigation based on URL commands.
    /// - Parameter url: The deep link URL to process.
    func handleDeepLink(url: URL) {
        guard url.scheme == "webexconnect", url.host == "command" else { return }
        
        let notificationName: String?
        
        switch url.lastPathComponent {
        case "messaging":
            notificationName = "NavigateToMessaging"
        case "notifications":
            notificationName = "NavigateToNotifications"
        case "logout":
            logOut()
            return
        default:
            return
        }
        
        if let name = notificationName {
            NotificationCenter.default.post(name: Notification.Name(name), object: nil)
        }
    }
    
    /// Logs out the user by unregistering from WebexConnect and updating the state.
    func logOut() {
        // WebexConnectSDK: unregisters the device profile
        webexConnect.unregister { [weak self] response, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.isRegistered = false
                } else {
                    print("Error during unregister: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}
