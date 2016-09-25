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
        let todoDictionary = UserDefaults.standard.dictionary(forKey: ITEMS_KEY) ?? [:]

        let items = Array(todoDictionary.values)
		return items.map({
			let item = $0 as! [String:AnyObject]
			return TodoItem(deadline: item["deadline"] as! Date, title: item["title"] as! String, UUID: item["UUID"] as! String!)
		}).sorted { (left, right) -> Bool in
			return left.deadline.compare(right.deadline) == .orderedAscending
		}
    }

    func add(_ item: TodoItem) {
        // persist a representation of this todo item in NSUserDefaults
        var todoDictionary = UserDefaults.standard.dictionary(forKey: ITEMS_KEY) ?? Dictionary() // if todoItems hasn't been set in user defaults, initialize todoDictionary to an empty dictionary using nil-coalescing operator (??)
        todoDictionary[item.UUID] = ["deadline": item.deadline, "title": item.title, "UUID": item.UUID] // store NSData representation of todo item in dictionary with UUID as key
        UserDefaults.standard.set(todoDictionary, forKey: ITEMS_KEY) // save/overwrite todo item list
        
        // create a corresponding local notification
        let notification = UILocalNotification()
        notification.alertBody = "Todo Item \"\(item.title)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = item.deadline as Date // todo item due date (when notification will be fired)
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["title": item.title, "UUID": item.UUID] // assign a unique identifier to the notification so that we can retrieve it later
        notification.category = "TODO_CATEGORY"
        
        UIApplication.shared.scheduleLocalNotification(notification)
        
        self.setBadgeNumbers()
    }
    
    func remove(_ item: TodoItem) {
        let scheduledNotifications: [UILocalNotification]? = UIApplication.shared.scheduledLocalNotifications
        guard scheduledNotifications != nil else {return} // Nothing to remove, so return

        for notification in scheduledNotifications! { // loop through notifications...
            if (notification.userInfo!["UUID"] as! String == item.UUID) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
                UIApplication.shared.cancelLocalNotification(notification) // there should be a maximum of one match on UUID
                break
            }
        }
        
        if var todoItems = UserDefaults.standard.dictionary(forKey: ITEMS_KEY) {
            todoItems.removeValue(forKey: item.UUID)
            UserDefaults.standard.set(todoItems, forKey: ITEMS_KEY) // save/overwrite todo item list
        }
        
        self.setBadgeNumbers()
    }
    
    func scheduleReminder(forItem item: TodoItem) {
        let notification = UILocalNotification() // create a new reminder notification
        notification.alertBody = "Reminder: Todo Item \"\(item.title)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes from current time
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["title": item.title, "UUID": item.UUID] // assign a unique identifier to the notification that we can use to retrieve it later
        notification.category = "TODO_CATEGORY"
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    func setBadgeNumbers() {
        let scheduledNotifications: [UILocalNotification]? = UIApplication.shared.scheduledLocalNotifications // all scheduled notifications
        guard scheduledNotifications != nil else {return} // nothing to remove, so return
        
        let todoItems: [TodoItem] = self.allItems()
        
        // we can't modify scheduled notifications, so we'll loop through the scheduled notifications and
        //
        var notifications: [UILocalNotification] = []

        for notification in scheduledNotifications! {
            print(UIApplication.shared.scheduledLocalNotifications!.count)
            let overdueItems = todoItems.filter({ (todoItem) -> Bool in // array of to-do items...
                // ...in which item deadline is on or before notification fire date
                return (todoItem.deadline.compare(notification.fireDate!) != .orderedDescending)
            })
        
            // set new badge number
            notification.applicationIconBadgeNumber = overdueItems.count            
            notifications.append(notification)
        }
        
        // don't modify a collection while you're iterating through it
        UIApplication.shared.cancelAllLocalNotifications() // cancel all notifications
        
        for note in notifications {
            UIApplication.shared.scheduleLocalNotification(note) // reschedule the new versions
        }
    }
}
