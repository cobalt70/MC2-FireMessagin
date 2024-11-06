//
//  appDelegate.swift
//  fcmNotificationServer
//
//  Created by Giwoo Kim on 5/25/24.
//

import Foundation

import Firebase
import UIKit



class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // FCM 등록 토큰 가져오기
        Messaging.messaging().delegate = self
        application.registerForRemoteNotifications()
        return true
    }
}

extension AppDelegate: MessagingDelegate {
    
    // FCM 등록 토큰이 갱신되거나 새로 발급될 때 호출됩니다.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM registration token:", fcmToken ?? "")
        // 토큰을 서버로 전송하거나 필요에 따라 저장합니다.
    }
}
