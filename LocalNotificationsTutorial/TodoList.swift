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
    private let savePath = (NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString).stringByAppendingPathComponent("todo.plist") // ~/todo.plist
    
    func allItems() -> [TodoItem] {
        let items: [AnyObject] = self.rawItems()
        return items.map({TodoItem(deadline: $0["deadline"] as! NSDate, title: $0["title"] as! String,  UUID: $0["UUID"] as! String!)}).sort({
            return ($0.deadline.compare($1.deadline) == .OrderedAscending)
        })
    }

    private func rawItems() -> [AnyObject] {
        var items: Array<AnyObject> = [] // default to an empty array...
        if (NSArray(contentsOfFile: self.savePath) != nil) { // ...because init?(contentsOfFile:) will return nil if file doesn't exist yet
            items = NSArray(contentsOfFile: self.savePath)! as Array<AnyObject> // load stored items, if available
        }
        return items
    }
    
    func setBadgeNumbers() {
        guard let notifications = UIApplication.sharedApplication().scheduledLocalNotifications else {
            return
        }

        let todoItems: [TodoItem] = self.allItems()
        
        for notification in notifications {
            let _ = todoItems.filter({ (todoItem) -> Bool in // array of to-do items...
                return (todoItem.deadline.compare(notification.fireDate!) != .OrderedDescending) // ...where item deadline is before or on notification fire date
            })
            UIApplication.sharedApplication().cancelLocalNotification(notification) // cancel old notification
            notification.applicationIconBadgeNumber = -1 // set new badge number
            UIApplication.sharedApplication().scheduleLocalNotification(notification) // reschedule notification
        }
    }
    
    func addItem(item: TodoItem) {
        // persist a representation of this todo item in a plist
        var items: [AnyObject] = self.rawItems()
        items.append(["title": item.title, "deadline": item.deadline, "UUID": item.UUID]) // add a dictionary representing this TodoItem instance
        (items as NSArray).writeToFile(self.savePath, atomically: true) // items casted as NSArray because writeToFile:atomically: is not available on Swift arrays
        
        // create a corresponding local notification
        let notification = UILocalNotification()
        notification.alertBody = "Todo Item \"\(item.title)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = item.deadline // todo item due date (when notification will be fired)
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["title": item.title, "UUID": item.UUID] // assign a unique identifier to the notification that we can use to retrieve it later
        notification.category = "TODO_CATEGORY"
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
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
    
    func removeItem(item: TodoItem) {
        guard let notifications = UIApplication.sharedApplication().scheduledLocalNotifications else {
            return
        }
        for notification in notifications { // loop through notifications...
            if (notification.userInfo!["UUID"] as! String == item.UUID) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
                UIApplication.sharedApplication().cancelLocalNotification(notification) // there should be a maximum of one match on UUID
                break
            }
        }
        
        var items: [AnyObject] = self.rawItems()
        items = items.filter {($0["UUID"] as! String? != item.UUID)} // remove item that matches UUID
        (items as NSArray).writeToFile(self.savePath, atomically: true) // overwrite todo.plist with new array
        
        self.setBadgeNumbers()
    }
}