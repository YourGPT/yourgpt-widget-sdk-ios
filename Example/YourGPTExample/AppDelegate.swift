import UIKit
import YourGPTSDK
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, YourGPTNotificationHandler {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // One-line push notification setup
        setupYourGPTNotifications(widgetUid: YourGPTWrapper.widgetUid)
        return true
    }

    // MARK: - APNs Token

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = YourGPTNotificationHelper.tokenString(from: deviceToken)
        YourGPTNotificationClient.shared.cacheToken(token)
        print("[YourGPTExample] APNs token received: \(token)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[YourGPTExample] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Background Remote Notifications (content-available)

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if YourGPTNotificationClient.shared.handleNotification(userInfo) {
            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
