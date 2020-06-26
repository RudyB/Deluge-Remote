//
//  AppDelegate.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/9/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Houston
import UIKit
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

    var splitViewDelegate = SplitViewDelegate()

    // swiftlint:disable:next line_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let consoleDest = ConsoleDestination()
        
        let fileDest = FileDestination()
        fileDest.logFileURL = getLogFile();
        fileDest.minLevel = .info
        fileDest.showLogLevelEmoji = false
        
        Logger.add(destination: consoleDest)
        Logger.add(destination: fileDest)
        
        IQKeyboardManager.shared.enable = true

        if let splitViewController = self.window?.rootViewController as? UISplitViewController,
            let navigationController = splitViewController.viewControllers.last as? UINavigationController {
            splitViewController.delegate = splitViewDelegate
            splitViewController.preferredDisplayMode = .allVisible
            navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            navigationController.topViewController?.navigationItem.leftItemsSupplementBackButton = true
        }
        Logger.info("Application Launching")
        return true
    }

    func applicationDidFinishLaunching(_ application: UIApplication) {
        return
    }

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state.
        // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message)
        // or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks.
        // Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough
        // application state information to restore your application to its current state in case it is terminated later
		// If your application supports background execution,
        // this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state;
        // here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive.
        // If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate.
        // Save data if appropriate. See also applicationDidEnterBackground:.
	}

    // swiftlint:disable:next line_length
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        Logger.debug(url)
        
        if url.isFileURL
        {
            let secureResource = url.startAccessingSecurityScopedResource()
            defer { if secureResource { url.stopAccessingSecurityScopedResource() } }
            
            guard
                let torrent = try? Data(contentsOf: url)
            else {
                Logger.error("Failed to create base64 encoded torrent")
                return false
            }
            NewTorrentNotifier.shared.userInfo = ["data": torrent]
        }
        else
        {
            NewTorrentNotifier.shared.userInfo = ["url": url]
        }
         
        return true
    }

}
