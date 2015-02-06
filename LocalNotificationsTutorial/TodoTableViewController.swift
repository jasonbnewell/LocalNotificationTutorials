//
//  TodoTableViewController.swift
//  LocalNotificationsTutorial
//
//  Created by Jason Newell on 1/30/15.
//
//

import UIKit

class TodoTableViewController: UITableViewController {
    var todoItems: [TodoItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshList", name: "TodoListShouldRefresh", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshList()
    }
    
    func refreshList() {
        todoItems = TodoList().allItems()
        if (todoItems.count >= 64) {
            self.navigationItem.rightBarButtonItem!.enabled = false // disable 'add' button
        }
        tableView.reloadData()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("todoCell", forIndexPath: indexPath) as UITableViewCell // retrieve the prototype cell (subtitle style)
        let todoItem = todoItems[indexPath.row] as TodoItem
        
        cell.textLabel?.text = todoItem.title as String!
        if (todoItem.isOverdue) { // the current time is later than the to-do item's deadline
            cell.detailTextLabel?.textColor = UIColor.redColor()
        } else {
            cell.detailTextLabel?.textColor = UIColor.blackColor() // we need to reset this because a cell with red subtitle may be returned by dequeueReusableCellWithIdentifier:indexPath:
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "'Due' MMM dd 'at' h:mm a" // example: "Due Jan 01 at 12:00 PM"
        cell.detailTextLabel?.text = dateFormatter.stringFromDate(todoItem.deadline)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true // all cells are editable
    }
    
    override func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String! {
        return "Complete" // alternate text for delete button
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete { // the only editing style we'll support
            // Delete the row from the data source
            var item = todoItems.removeAtIndex(indexPath.row) // remove TodoItem from notifications array, assign removed item to 'item'
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            TodoList().removeItem(item) // delete backing property list entry and unschedule local notification (if it still exists)
            self.navigationItem.rightBarButtonItem!.enabled = true // we definitely have under 64 notifications scheduled now, make sure 'add' button is enabled
        }
    }
}
