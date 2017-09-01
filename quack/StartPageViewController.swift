//
//  StartPageViewController.swift
//  quack
//
//  Created by Marco Booth on 01/09/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import UIKit

class StartPageViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func unwindToRootViewController(segue: UIStoryboardSegue) {
        print("Unwind to Root View Controller")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let name = textField.text else {
            print("I'm afraid we need a name")
            return
        }
        
        segue.destination.title = name
    }

}
