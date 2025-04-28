//
//  LoginViewModel.swift
//  WebexConnectDemo
//
import Foundation
import WebexConnectCore

/// ViewModel for handling login and registration logic.
/// Uses ObservableObject to bind to SwiftUI view.
class LoginViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var userId: String = ""                        // Stores the user ID entered in the UI
    @Published var showLoading: Bool = false                  // Controls the loading spinner
    @Published var showConversationsView: Bool = false        // Triggers navigation to the next screen
    @Published var alertModel: AlertViewModel?                // Model to show alerts using `.alert(item:)`

    // WebexConnectSDK: Retrieve the shared WebexConnect instance.
    private let webexConnect = WebexConnectProvider.instance
    
    /// Initiates the registration flow after validating user input and SDK state.
    ///
    /// This function performs the following:
    /// 1. Dismisses the keyboard if it's open.
    /// 2. Validates that the `userId` field is not empty.
    /// 3. Checks if the Webex Connect SDK has been successfully started.
    /// 4. Creates a `DeviceProfile` with the provided user ID.
    /// 5. Initiates the device registration process via the `registerDevice` method.
    ///
    /// If any of the validations fail, an `AlertViewModel` is populated to show the appropriate error.
    func startRegistration() {
        // Dismiss keyboard
        hideKeyboard()

        // Validate user input
        guard !userId.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertModel = AlertViewModel(title: "Error", message: "User ID cannot be empty")
            return
        }

        // WebexConnectSDK: Check if the SDK is initialized and ready
        guard webexConnect.isStarted else {
            alertModel = AlertViewModel(title: "SDK Error", message: "Webex Connect SDK is not started")
            return
        }

        // WebexConnectSDK: Create a new DeviceProfile with the default device id and the user id
        // WebexConnectSDK: Using the default device id for the device. You can use your own device id if you have one
        let deviceProfile = DeviceProfile(deviceId: DeviceProfile.defaultDeviceId(), userId: userId, isGuest: false)

        // Initiate the registration process
        registerDevice(with: deviceProfile)
    }

    // MARK: - Private Methods

    /// Calls Webex Connect SDK's register method with the configured device profile.
    /// - Parameter deviceProfile: A profile that uniquely identifies a device-user combo.
    private func registerDevice(with deviceProfile: DeviceProfile) {
        showLoading = true

        // WebexConnectSDK: Register the device using the provided DeviceProfile.
        // The completion handler returns an error if registration fails, or nil if successful.
        webexConnect.register(deviceProfile: deviceProfile) { [weak self] response, error in
            DispatchQueue.main.async {
                self?.showLoading = false
                if let error = error {
                    self?.alertModel = AlertViewModel(title: "Registration Failed", message: error.localizedDescription)
                } else {
                    self?.showConversationsView = true
                }
            }
        }
    }
}

/// A simple model for handling alert content.
/// Conforms to `Identifiable` so it can be used with `.alert(item:)` in SwiftUI.
struct AlertViewModel: Identifiable {
    var id = UUID()
    var title: String
    var message: String
}
