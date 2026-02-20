//
//  SceneDelegate.swift
//  Layout
//
//  Created by Byeongjo Koo.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  // MARK: Properties

  var window: UIWindow?

  // MARK: UIWindowSceneDelegate

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }
    
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = MemoViewController()
    window.makeKeyAndVisible()
    self.window = window
  }
}
