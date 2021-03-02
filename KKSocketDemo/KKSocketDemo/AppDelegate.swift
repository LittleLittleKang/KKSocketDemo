//
//  AppDelegate.swift
//  KKSocketDemo
//
//  Created by 看影成痴 on 2021/2/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var hostReachability = Reachability()
    var networkStatus: NetworkStatus?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 开始监听网络状态 (加这个, 国行版第一次下载运行App就会弹出数据权限提示框)
        self.starNetwordStatusNotifier()
        
        return true
    }

    
    // 开始监听网络状态
    func starNetwordStatusNotifier() {
        // 添加通知: 网络状态发生改变时
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: NSNotification.Name(rawValue: "kNetworkReachabilityChangedNotification"), object: nil)
        self.hostReachability = Reachability.init(hostName: "www.apple.com")
        self.hostReachability.startNotifier()
    }
    
    
    // 通知: 网络状态发生改变时
    @objc func reachabilityChanged(note: Notification) {
        let curReadch = note.object as! Reachability
        self.networkStatus = curReadch.currentReachabilityStatus()
    }
}

