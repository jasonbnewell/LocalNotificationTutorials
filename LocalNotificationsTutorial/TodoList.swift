//
//  TodoList.swift
//  LocalNotificationsTutorial
//
//  Created by Jason Newell on 2/3/15.
//
//

import Foundation
import UIKit

class TodoList {
    class var sharedInstance : TodoList {
        struct Static {
            static let instance : TodoList = TodoList()
        }
        return Static.instance
    }

    private let ITEMS_KEY = "todoItems"
    
    func allItems() -> [TodoItem] {
        let todoDictionary = NSUserDefaults.standardUserDefaults().dictionaryForKey(ITEMS_KEY) ?? [:]
        let items = Array(todoDictionary.values)
        return items.map({TodoItem(deadline: $0["deadline"] as! NSDate, title: $0["title"] as! String, UUID: $0["UUID"] as! String!)}).sort({(left: TodoItem, right:TodoItem) -> Bool in
            (left.deadline.compare(right.deadline) == .OrderedAscending)
        })
    }
    
    func addItem(item: TodoItem) {
        // persist a representation of this todo item in NSUserDefaults
        var todoDictionary = NSUserDefaults.standardUserDefaults().dictionaryForKey(ITEMS_KEY) ?? Dictionary() // if todoItems hasn't been set in user defaults, initialize todoDictionary to an empty dictionary using nil-coalescing operator (??)
        todoDictionary[item.UUID] = ["deadline": item.deadline, "title": item.title, "UUID": item.UUID] // store NSData representation of todo item in dictionary with UUID as key
        NSUserDefaults.standardUserDefaults().setObject(todoDictionary, forKey: ITEMS_KEY) // save/overwrite todo item list
        
        // create a corresponding local notification
        let notification = UILocalNotification()
        notification.alertBody = "Todo Item \"\(item.title)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = item.deadline // todo item due date (when notification will be fired)
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["title": item.title, "UUID": item.UUID] // assign a unique identifier to the notification so that we can retrieve it later
        notification.category = "TODO_CATEGORY"
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
        self.setBadgeNumbers()
    }
    
    func removeItem(item: TodoItem) {
        let scheduledNotifications: [UILocalNotification]? = UIApplication.sharedApplication().scheduledLocalNotifications
        guard scheduledNotifications != nil else {return} // Nothing to remove, so return

        for notification in scheduledNotifications! { // loop through notifications...
            if (notification.userInfo!["UUID"] as! String == item.UUID) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
                UIApplication.sharedApplication().cancelLocalNotification(notification) // there should be a maximum of one match on UUID
                break
            }
        }
        
        if var todoItems = NSUserDefaults.standardUserDefaults().dictionaryForKey(ITEMS_KEY) {
            todoItems.removeValueForKey(item.UUID)
            NSUserDefaults.standardUserDefaults().setObject(todoItems, forKey: ITEMS_KEY) // save/overwrite todo item list
        }
        
        self.setBadgeNumbers()
    }
    
    func scheduleReminderforItem(item: TodoItem) {
        let notification = UILocalNotification() // create a new reminder notification
        notification.alertBody = "Reminder: Todo Item \"\(item.title)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = NSDate().dateByAddingTimeInterval(30 * 60) // 30 minutes from current time
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["title": item.title, "UUID": item.UUID] // assign a unique identifier to the notification that we can use to retrieve it later
        notification.category = "TODO_CATEGORY"
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func setBadgeNumbers() {
        let scheduledNotifications: [UILocalNotification]? = UIApplication.sharedApplication().scheduledLocalNotifications // all scheduled notifications
        guard scheduledNotifications != nil else {return} // nothing to remove, so return
        
        let todoItems: [TodoItem] = self.allItems()
        
        // we can't modify scheduled notifications, so we'll loop through the scheduled notifications and
        //
        var notifications: [UILocalNotification] = []

        for notification in scheduledNotifications! {
            print(UIApplication.sharedApplication().scheduledLocalNotifications!.count)
            let overdueItems = todoItems.filter({ (todoItem) -> Bool in // array of to-do items...
                // ...in which item deadline is on or before notification fire date
                return (todoItem.deadline.compare(notification.fireDate!) != .OrderedDescending)
            })
        
            // set new badge number
            notification.applicationIconBadgeNumber = overdueItems.count            
            notifications.append(notification)
        }
        
        // don't modify a collection while you're iterating through it
        UIApplication.sharedApplication().cancelAllLocalNotifications() // cancel all notifications
        
        for note in notifications {
            UIApplication.sharedApplication().scheduleLocalNotification(note) // reschedule the new versions
        }
    }
}