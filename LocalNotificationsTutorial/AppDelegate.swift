//
//  AppDelegate.swift
//  LocalNotificationsTutorial
//
//  Created by Jason Newell on 1/30/15.
//
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        let completeAction = UIMutableUserNotificationAction()
        completeAction.identifier = "COMPLETE_TODO" // the unique identifier for this action
        completeAction.title = "Complete" // title for the action button
        completeAction.activationMode = .background // UIUserNotificationActivationMode.Background - don't bring app to foreground
        completeAction.isAuthenticationRequired = false // don't require unlocking before performing action
        completeAction.isDestructive = true // display action in red
        
        let remindAction = UIMutableUserNotificationAction()
        remindAction.identifier = "REMIND"
        remindAction.title = "Remind in 30 minutes"
        remindAction.activationMode = .background
        remindAction.isDestructive = false
        
        let todoCategory = UIMutableUserNotificationCategory() // notification categories allow us to create groups of actions that we can associate with a notification
        todoCategory.identifier = "TODO_CATEGORY"
        todoCategory.setActions([remindAction, completeAction], for: .default) // UIUserNotificationActionContext.Default (4 actions max)
        todoCategory.setActions([completeAction, remindAction], for: .minimal) // UIUserNotificationActionContext.Minimal - for when space is limited (2 actions max)

        // we're now providing a set containing our category as an argument
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: Set([todoCategory])))
        return true
    }

	func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {

        let item = TodoItem(deadline: notification.fireDate!, title: notification.userInfo!["title"] as! String, UUID: notification.userInfo!["UUID"] as! String!)
        switch (identifier!) {
        case "COMPLETE_TODO":
            TodoList.sharedInstance.remove(item)
        case "REMIND":
            TodoList.sharedInstance.scheduleReminder(forItem: item)
        default: // switch statements must be exhaustive - this condition should never be met
            print("Error: unexpected notification action identifier!")
        }
        completionHandler() // per developer documentation, app will terminate if we fail to call this
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
		// It's generally better to define one static variable instead of inlining the Notificaiton.Name constructor.
        NotificationCenter.default.post(name: Notification.Name("TodoListShouldRefresh"), object: self)
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: Notification.Name("TodoListShouldRefresh") as NSNotification.Name, object: self)
    }

    func applicationWillResignActive(_ application: UIApplication) { // fired when user quits the application
        let todoItems: [TodoItem] = TodoList.sharedInstance.allItems() // retrieve list of all to-do items
        let overdueItems = todoItems.filter({ (todoItem) -> Bool in
            return todoItem.deadline.compare(Date()) != .orderedDescending
        })
        UIApplication.shared.applicationIconBadgeNumber = overdueItems.count  // set our badge number to number of overdue items
    }

}

