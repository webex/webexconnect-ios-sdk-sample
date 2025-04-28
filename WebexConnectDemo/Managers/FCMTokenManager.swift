import Foundation
import FirebaseCore
import FirebaseMessaging
import WebexConnectPush
import WebexConnectCore

class FCMTokenManager: NSObject, MessagingDelegate, FCMPushProvider {
    var fcmToken: String?

    /// Initializes an instance of `FCMTokenManager` and configures Firebase for messaging.
    ///
    /// - This initializes the Firebase app configuration and sets the `FCMTokenManager` as the delegate for the `Messaging` instance.
    override init() {
        super.init()

        FirebaseApp.configure()

        Messaging.messaging().delegate = self
    }

    /// Retrieves the current FCM token.
    ///
    /// - Returns: The current FCM token, or `nil` if the token is not available.
    func getToken() -> String? {
        return self.fcmToken
    }

    /// Fetches the FCM token using the APNs device token.
    ///
    /// - Parameter data: The device token received from APNs (Apple Push Notification service).
    /// - Parameter completionHandler: A closure that receives the FCM token and any error that may occur.
    func fetchFcmToken(usingAPNSToken data: Data, completionHandler: @escaping (String?, Error?) -> Void) {
#if DEBUG
        let apnsTokenType: MessagingAPNSTokenType = .sandbox
#else
        let apnsTokenType: MessagingAPNSTokenType = .unknown
#endif
        Messaging.messaging().setAPNSToken(data, type: apnsTokenType)

        Messaging.messaging().token { newFcmToken, error in
            self.fcmToken = newFcmToken
            completionHandler(newFcmToken, error)
        }
    }

    /// Subscribes to a specific FCM topic.
    ///
    /// - Parameter topic: The topic to subscribe to.
    /// - Parameter completionHandler: A closure that receives any error that occurs during the subscription process.
    func subscribeToTopic(_ topic: String, completionHandler: @escaping (Error?) -> Void) {
        Messaging.messaging().subscribe(toTopic: topic, completion: completionHandler)
    }

    /// Unsubscribes from a specific FCM topic.
    ///
    /// - Parameter topic: The topic to unsubscribe from.
    func unsubscribeFromTopic(_ topic: String) {
        Messaging.messaging().unsubscribe(fromTopic: topic)
    }

    /// Handles the reception of the FCM registration token.
    ///
    /// This method is called when the app successfully receives or refreshes its FCM registration token. The token is stored for future use and sent to the push notification service.
    ///
    /// - Parameter messaging: The `Messaging` instance that received the registration token.
    /// - Parameter fcmToken: The FCM token that was received.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM registration token: \(String(describing: fcmToken))")
        self.fcmToken = fcmToken
        processFCMPushToken()
    }

    /// Processes the FCM push token if the device is registered.
    ///
    /// This method checks if the device is registered with WebexConnect, and if so, sends the FCM token to the push messaging provider for processing.
    func processFCMPushToken() {
        if let fcmToken, WebexConnectProvider.instance.isRegistered {
            PushMessagingProvider.instance.processPushToken(fcmToken, type: .fcm, completionHandler: { _ in })
        }
    }
}
