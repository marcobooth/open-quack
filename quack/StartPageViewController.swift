//
//  StartPageViewController.swift
//  quack
//
//  Created by Marco Booth on 01/09/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import UIKit
import AVFoundation

class StartPageViewController: UIViewController {
    @IBOutlet weak var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.textField.layer.cornerRadius = 5
        
        // TODO: Ask Teo if app memory should be cleared each time app loads, in case of errors, ensures that 
        // the recording will be deleted. Will pile up in memory if this were to happen
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    @IBAction func unwindToRootViewController(segue: UIStoryboardSegue) {
        print("Unwind to Root View Controller")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let name = textField.text, textField.text != "" else {
            print("I'm afraid we need a name")
            self.showErrorMessage(title: "Error", message: "Please provide a name for the event")
            return
        }
        
        if AVAudioSession.sharedInstance().recordPermission() == .denied {
            self.showErrorMessage(title: "Permissions error", message: "This app does not have permission to record, please change this in Settings -> Privacy")
            return
        }
        
        segue.destination.title = name
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension UIViewController {
    func showErrorMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
