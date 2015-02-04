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
        var items: [AnyObject] = self.rawItems()
        return items.map({TodoItem(deadline: $0["deadline"] as NSDate, title: $0["title"] as String,  UUID: $0["UUID"] as String!)}).sorted({
            return ($0.deadline.compare($1.deadline) == .OrderedAscending)
        })
    }

    private func rawItems() -> [AnyObject] {
        var items: Array<AnyObject> = [] // default to an empty array...
        if (NSArray(contentsOfFile: self.savePath) != nil) { // ...because init?(contentsOfFile:) will return nil if file doesn't exist yet
            items = NSArray(contentsOfFile: self.savePath)! // load stored items, if available
        }
        return items
    }
    
    func addItem(item: TodoItem) {
        // persist a representation of this todo item in a plist
        var items: [AnyObject] = self.rawItems()
        items.append(["title": item.title, "deadline": item.deadline, "UUID": item.UUID]) // add a dictionary representing this TodoItem instance
        (items as NSArray).writeToFile(self.savePath, atomically: true) // items casted as NSArray because writeToFile:atomically: is not available on Swift arrays
        
        // create a corresponding local notification
        var notification = UILocalNotification()
        notification.alertBody = "Todo Item \"\(item.title)\" Is Overdue" // text that will be displayed in the notification
        notification.alertAction = "open" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
        notification.fireDate = item.deadline // todo item due date (when notification will be fired)
        notification.soundName = UILocalNotificationDefaultSoundName // play default sound
        notification.userInfo = ["UUID": item.UUID] // assign a unique identifier to the notification so that we can retrieve it later
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
    }
    
    func removeItem(item: TodoItem) {
        for notification in UIApplication.sharedApplication().scheduledLocalNotifications as [UILocalNotification] { // loop through notifications...
            if (notification.userInfo!["UUID"] as String == item.UUID) { // ...and cancel the notification that corresponds to this TodoItem instance (matched by UUID)
                UIApplication.sharedApplication().cancelLocalNotification(notification) // there should be a maximum of one match on UUID
                break
            }
        }
        
        var items: [AnyObject] = self.rawItems()
        items = items.filter {($0["UUID"] as String? != item.UUID)} // remove item that matches UUID
        (items as NSArray).writeToFile(self.savePath, atomically: true) // overwrite todo.plist with new array
    }
}