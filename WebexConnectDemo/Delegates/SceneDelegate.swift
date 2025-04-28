import Foundation
import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
    var window: UIWindow?
    override init() { }

    func sceneWillEnterForeground(_ scene: UIScene) {
        if let appDelegate = UIApplication.shared.delegate {
            appDelegate.applicationWillEnterForeground?(UIApplication.shared)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if let appDelegate =  UIApplication.shared.delegate {
            appDelegate.applicationDidEnterBackground?(UIApplication.shared)
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let response = connectionOptions.notificationResponse {
            print("scene willConnectTo session notificationResponse",response.notification.request.content.userInfo)
        }
    }

}
