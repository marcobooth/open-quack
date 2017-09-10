//
//  Alert.swift
//  quack
//
//  Created by Marco Booth on 10/09/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func textFieldAlert(name: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: name, message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {action in
            print("cancel was tapped")
        }))
        
        return alert
    }
}
