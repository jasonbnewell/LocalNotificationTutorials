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
        NotificationCenter.default.addObserver(self, selector: #selector(TodoTableViewController.refreshList), name: NSNotification.Name(rawValue: "TodoListShouldRefresh"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshList()
    }
    
    func refreshList() {
        todoItems = TodoList.sharedInstance.allItems()
        if (todoItems.count >= 64) {
            self.navigationItem.rightBarButtonItem!.isEnabled = false // disable 'add' button
        }
        tableView.reloadData()
    }

	override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems.count
    }
    
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "todoCell", for: indexPath as IndexPath) // retrieve the prototype cell (subtitle style)
        let todoItem = todoItems[indexPath.row] as TodoItem
        
        cell.textLabel?.text = todoItem.title as String!
        if (todoItem.isOverdue) { // the current time is later than the to-do item's deadline
            cell.detailTextLabel?.textColor = UIColor.red
        } else {
            cell.detailTextLabel?.textColor = UIColor.black // we need to reset this because a cell with red subtitle may be returned by dequeueReusableCellWithIdentifier:indexPath:
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "'Due' MMM dd 'at' h:mm a" // example: "Due Jan 01 at 12:00 PM"
        cell.detailTextLabel?.text = dateFormatter.string(from: todoItem.deadline as Date)
        
        return cell
    }

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true // all cells are editable
    }


	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete { // the only editing style we'll support
            // Delete the row from the data source
            let item = todoItems.remove(at: indexPath.row) // remove TodoItem from notifications array, assign removed item to 'item'
            tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
            TodoList.sharedInstance.remove(item) // delete backing property list entry and unschedule local notification (if it still exists)
            self.navigationItem.rightBarButtonItem!.isEnabled = true // we definitely have under 64 notifications scheduled now, make sure 'add' button is enabled
        }
    }
}
