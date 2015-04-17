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


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let completeAction = UIMutableUserNotificationAction()
        completeAction.identifier = "COMPLETE_TODO" // the unique identifier for this action
        completeAction.title = "Complete" // title for the action button
        completeAction.activationMode = .Background // UIUserNotificationActivationMode.Background - don't bring app to foreground
        completeAction.authenticationRequired = false // don't require unlocking before performing action
        completeAction.destructive = true // display action in red
        
        let remindAction = UIMutableUserNotificationAction()
        remindAction.identifier = "REMIND"
        remindAction.title = "Remind in 30 minutes"
        remindAction.activationMode = .Background
        remindAction.destructive = false
        
        let todoCategory = UIMutableUserNotificationCategory() // notification categories allow us to create groups of actions that we can associate with a notification
        todoCategory.identifier = "TODO_CATEGORY"
        todoCategory.setActions([remindAction, completeAction], forContext: .Default) // UIUserNotificationActionContext.Default (4 actions max)
        todoCategory.setActions([completeAction, remindAction], forContext: .Minimal) // UIUserNotificationActionContext.Minimal - for when space is limited (2 actions max)
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Badge | .Sound, categories: NSSet(array: [todoCategory]) as Set<NSObject>)) // we're now providing a set containing our category as an argument
        return true
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        var item = TodoItem(deadline: notification.fireDate!, title: notification.userInfo!["title"] as! String, UUID: notification.userInfo!["UUID"] as! String!)
        switch (identifier!) {
        case "COMPLETE_TODO":
            TodoList.sharedInstance.removeItem(item)
        case "REMIND":
            TodoList.sharedInstance.scheduleReminderforItem(item)
        default: // switch statements must be exhaustive - this condition should never be met
            println("Error: unexpected notification action identifier!")
        }
        completionHandler() // per developer documentation, app will terminate if we fail to call this
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        NSNotificationCenter.defaultCenter().postNotificationName("TodoListShouldRefresh", object: self)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        NSNotificationCenter.defaultCenter().postNotificationName("TodoListShouldRefresh", object: self)
    }

    func applicationWillResignActive(application: UIApplication) { // fired when user quits the application
        var todoItems: [TodoItem] = TodoList.sharedInstance.allItems() // retrieve list of all to-do items
        var overdueItems = todoItems.filter({ (todoItem) -> Bool in
            return todoItem.deadline.compare(NSDate()) != .OrderedDescending
        })
        UIApplication.sharedApplication().applicationIconBadgeNumber = overdueItems.count  // set our badge number to number of overdue items
    }

}

