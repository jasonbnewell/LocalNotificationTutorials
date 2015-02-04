//
//  TodoSchedulingViewController.swift
//  TodoNotificationsTutorial
//
//  Created by Jason Newell on 1/25/15.
//  Copyright (c) 2015 Jason Newell. All rights reserved.
//

import UIKit

class TodoSchedulingViewController: UIViewController {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var deadlinePicker: UIDatePicker!
    
    @IBAction func savePressed(sender: UIButton) {
        if (countElements(titleField.text.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())) > 0) { // only save if titlefield text contains non-whitespace characters
            let todoItem = TodoItem(deadline: deadlinePicker.date, title: titleField.text, UUID: NSUUID().UUIDString)
            TodoList().addItem(todoItem) // schedule a local notification to persist this item
            self.navigationController?.popToRootViewControllerAnimated(true) // return to list view where the newly created item will be displayed
        } else { // text field was blank or contained only whitespace
            var alertController = UIAlertController(title: "Error", message: "You must give this todo item a title", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
}