import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // TODO: Uncomment the next section after adding SupportHomeViewController.swift to Xcode project
        /*
        let mainViewController: UIViewController
        if #available(iOS 13.0, *) {
            mainViewController = SupportHomeViewController()
        } else {
            mainViewController = ViewController()
        }
        */
        
        // Temporary: Use original ViewController until SupportHomeViewController is added to project
        let mainViewController = ViewController()
        
        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}