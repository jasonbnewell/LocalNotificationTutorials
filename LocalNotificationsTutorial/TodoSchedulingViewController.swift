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
    
	@IBAction func savePressed(_ sender: UIButton) {
        let todoItem = TodoItem(deadline: deadlinePicker.date, title: titleField.text!, UUID: NSUUID().uuidString)
        TodoList.sharedInstance.add(todoItem) // schedule a local notification to persist this item
		let _ = self.navigationController?.popToRootViewController(animated: true) // return to list view
    }
}
