//
//  ViewController.swift
//  quack
//
//  Created by Marco Booth on 31/08/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var recorder : AVAudioRecorder?
    var recordingFileLocation : URL?
    var people : [String]? = ["Jerome", "Jeff"]
    
    @IBOutlet weak var startOrStopButton : UIBarButtonItem!
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var recordButton : UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.isUserInteractionEnabled = false
        self.recordButton.isEnabled = false
        
        self.setSessionRecord()
    }

    @IBAction func startOrStopRecording(_ sender: UIBarButtonItem) {
        if self.recorder == nil {
            let alert = textFieldAlert(name: "Recorder", message: "Name the recording")
            alert.addAction(UIAlertAction(title: "Set title", style: .default, handler: {action in
                print("set title was tapped")
                self.title = alert.textFields?[0].text
                self.startRecording()
            }))
            self.present(alert, animated:true, completion:nil)
        } else {
            self.stopRecording(sendToServer: true)
        }
    }
    
    func startRecording() {
        print("start the recording")
        
        self.startOrStopButton.title = "Stop"
        self.recordButton.isEnabled = true
        self.collectionView.isUserInteractionEnabled = true
        self.recordWithPermission()
    }
    
    func stopRecording(sendToServer: Bool) {
        print("stop the recording")
        self.startOrStopButton.title = "Start"
        self.recordButton.isEnabled = false
        self.collectionView.isUserInteractionEnabled = false
        
        self.recorder?.stop()
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        } catch {
            print("could not make session inactive")
            print(error.localizedDescription)
        }
        
        self.recorder = nil
        if sendToServer == true {
            // begin processing - maybe should disable view while in processing
        }
    }
    
    func recordWithPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission() {
            [unowned self] granted in
            if granted {
                
                DispatchQueue.main.async {
                    print("Permission to record granted")
                    self.setupRecorder()
                    self.recorder?.record()
                }
            } else {
                // TODO: maybe leave a message saying they can only change this in Settings
                print("Permission to record not granted")
                self.stopRecording(sendToServer: false)
            }
        }
        
        if AVAudioSession.sharedInstance().recordPermission() == .denied {
            print("permission denied")
        }
    }
    
    
    func setupRecorder() {
        let currentFilename : String
        if let title = self.title {
            currentFilename = title + ".wav"
        } else {
            print("error: unNamed event, we gots a problem")
            self.stopRecording(sendToServer: false)
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("documents directory, what is this?", documentsDirectory)
        print("more of the same", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        self.recordingFileLocation = documentsDirectory.appendingPathComponent(currentFilename)
        print("writing to soundfile url: '\(recordingFileLocation!)'")
        
        guard let recordingLocation = self.recordingFileLocation else {
            self.stopRecording(sendToServer: false)
            return
        }
        
        // Add this as a pull request from where I got the code,
        // https://stackoverflow.com/questions/9303875/fileexistsatpath-returning-no-for-files-that-exist
        if FileManager.default.fileExists(atPath: recordingLocation.path) {
            // TEST: same file name
            print("soundfile \(recordingFileLocation?.absoluteString ?? "") exists")
            self.stopRecording(sendToServer: false)
            return
        }
        
        let recordSettings:[String : Any] = [
            AVFormatIDKey:             kAudioFormatLinearPCM,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            //            AVEncoderBitRateKey :      32000,
            AVNumberOfChannelsKey:     1,
            AVSampleRateKey :          16000.0
        ]
        
        
        do {
            self.recorder = try AVAudioRecorder(url: recordingLocation, settings: recordSettings)
            self.recorder?.delegate = self
            self.recorder?.prepareToRecord() // creates/overwrites the file at soundFileURL
        } catch {
            recorder = nil
            self.stopRecording(sendToServer: false)
            print(error.localizedDescription)
        }
        
    }
    
    func setSessionRecord() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSessionCategoryRecord)
        } catch {
            print("could not set session category")
            print(error.localizedDescription)
        }
        
        do {
            try session.setActive(true)
        } catch {
            print("could not make session active")
            print(error.localizedDescription)
        }
    }
}

// MARK: AVAudioRecorderDelegate
extension ViewController : AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                         successfully flag: Bool) {
        print("audioRecorderDidFinishRecording")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                          error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
}

extension ViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // The 1 is the extra cell used for adding additional people to the collection
        return 1 + (self.people?.count ?? 0)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (indexPath.row == self.collectionView.numberOfItems(inSection: 0) - 1) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "person", for: indexPath) as! PersonCollectionViewCell
        cell.name.text = people?[indexPath.row]
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath.row == self.collectionView.numberOfItems(inSection: 0) - 1) {
            let alert = textFieldAlert(name: "Add a person", message: "Someone will be added to the list")
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: {action in
                guard let name = alert.textFields?[0].text else {
                    return
                }
                self.people?.append(name)
                self.collectionView.reloadData()
            }))
            self.present(alert, animated:true, completion:nil)
        }
    }
}

extension ViewController {
    func textFieldAlert(name: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: name, message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {action in
            print("cancel was tapped")
        }))

        return alert
    }
}
