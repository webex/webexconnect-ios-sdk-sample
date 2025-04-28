import Foundation
import WebexConnectCore
import UserNotifications
import UIKit
import WebexConnectPush
import FirebaseMessaging
import WebexConnectInAppMessaging
import BackgroundTasks


class AppDelegate: WebexConnectAppDelegate, ObservableObject, UNUserNotificationCenterDelegate {

    let bgTaskId = "com.webexconnect.demo.refresh"
    let webexConnect = WebexConnectProvider.instance
    let logger = ConsoleLogger(logType: .fault)

    // MARK: Application life cycle methods
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any]? = nil) -> Bool {
        super.application(application, didFinishLaunchingWithOptions: launchOptions)

        // WebexConnectSDK: Create a new ConsoleLogger with LogLevel.Debug.
        LogManager.setConsoleLogger()
       
        // OR

        // To log messages to files with LogLevel.debug:
        // Uncomment the line below if you prefer file logging.
        // WebexConnectSDK: Create a new FileLogger with LogLevel.Debug.
        // LogManager.setFileLogger()

        
        // WebexConnectSDK:Get the PushMessaging instance
        let push = PushMessagingProvider.instance
        // WebexConnectSDK: Set the messaging delegate for the pushMessaging instance.
        push.pushMessagingDelegate = self
        // WebexConnectSDK: Set the fcm push provider if you want to use FCM for push notifications.
//        push.fcmPushProvider = FCMTokenManager()
        // WebexConnectSDK: Set the actions delegate responsible for handling push notification actions.
        push.actionsDelegate = self

        // WebexConnectSDK: Register the InAppNotificationModalViewBinderFactory with the InAppNotificationManager instance.
        push.inAppNotificationManager?.registerViewFactory(InAppNotificationModalViewBinderFactory())
       
        // WebexConnectSDK: Register the InAppNotificationBannerViewBinderFactory with the InAppNotificationManager instance.
        push.inAppNotificationManager?.registerViewFactory(InAppNotificationBannerViewBinderFactory())
        
        // WebexConnectSDK: Get the InAppMessaging instance.
        let inApp = InAppMessagingProvider.instance
        // WebexConnectSDK: Set the message store for the InAppMessaging instance.
        inApp.messageStore = DefaultMessageStore(password: "DefaultMessageStore")
        // WebexConnectSDK: Set the message synchronization policy to full,
        // Message sync process will be started by SDK, on the completion of InApp connection/security token change.
        inApp.messageSynchronizationPolicy = MessageSynchronizationPolicy(mode: .full)
        // WebexConnectSDK: Set the security token for the WebexConnect instance.
        // webexConnect.setSecurityToken("securityToken")
        
        
        let logMessage = "AppDelegate didFinishLaunchingWithOptions launchOptions: \(launchOptions ?? [:])"
        print(logMessage)
        logger.log(logType: .info, tag: #fileID, message: "application didFinishLaunchingWithOptions WebexConnect.isStarted: %@, launchOptions: %@", args: [String(describing: webexConnect.isStarted), String(describing: launchOptions)])

        return true
    }

    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
        logger.log(logType: .info, tag: #fileID, message: "application didReceiveRemoteNotification fetchCompletionHandler")
    }

    // MARK: Scene Delegate Configuration
    override func application( _ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions ) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self // 👈🏻
        return sceneConfig
    }
}

//MARK: PushMessagingDelegate
extension AppDelegate: PushMessagingDelegate {
    func didReceiveMessage(message: PushMessage, fromTap: Bool) {
        logger.log(logType: .debug, tag: #fileID, message: "AppDelegate didReceiveMessage with transactionId: %@", arg: message.transactionId ?? "nil")
    }
}


//MARK: PushActionsDelegate
extension AppDelegate: PushActionsDelegate {
    func handleAction(_ action: String, withIdentifier identifier: String, forMessage message: WebexConnectPush.PushMessage, responseInfo: [String : Any]?) -> Bool {
        print("handleAction \(action) withIdentifier: \(identifier), responseInfo: \(String(describing: responseInfo))")
        return true
    }
}
