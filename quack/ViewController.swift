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
    var audioExcerpts = [AudioExcerpt]()
    var currentExcerpt : AudioExcerpt?
    var currentPersonSpeaking : (name: String, startTime: TimeInterval, endTime: TimeInterval?)?
    
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var recordButton : UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setSessionRecord()
        self.recordWithPermission()
        
//        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleLongGesture(_:)))
//        self.collectionView.addGestureRecognizer(longPressGesture)

    }
    
    @IBAction func stopEvent(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "End event", message: "Please confirm that you would like the event to end", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {action in
            print("cancel was tapped")
        }))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: {action in
            self.stopRecording(sendToServer: true)
        }))
        self.present(alert, animated:true, completion:nil)
    }
    
    func stopRecording(sendToServer: Bool) {
        
        if self.currentExcerpt != nil {
            self.stopExcerpt()
        }
        
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
        
        print("audio excerpts", self.audioExcerpts)
        
        // Should delete all audio excerpts and put currentExcerpt at nil
        self.performSegue(withIdentifier: "unwindToStart", sender: nil)
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
    
    @IBAction func createExcerpt(_ sender: UIButton) {
        guard let currentTime = self.recorder?.currentTime else {
            print("no recorder, no time")
            return
        }
        
        if self.currentExcerpt == nil {
            self.currentExcerpt = AudioExcerpt(startTime: currentTime, timeDifference: 30.0)
            self.recordButton.setTitle("Stop Recording", for: .normal)
        } else {
            stopExcerpt()
        }
    }
    
    func stopExcerpt() {
        guard let currentTime = self.recorder?.currentTime else {
            print("no recorder, no time")
            return
        }
        
        if self.currentPersonSpeaking != nil {
            self.deselectRow(indexPath: nil)
        }
        
        self.currentExcerpt?.endTime = currentTime
        // Feel like this ! might be ok, maybe should remove it though
        self.audioExcerpts.append(self.currentExcerpt!)
        print("currentExcerpt", self.currentExcerpt)
        self.currentExcerpt = nil
        self.recordButton.setTitle("Record", for: .normal)
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
    
    //    func handleLongGesture(_ gesture: UILongPressGestureRecognizer) {
    //        print("im here", gesture.state.rawValue)
    //        switch(gesture.state) {
    //
    //        case UIGestureRecognizerState.began:
    //            guard let selectedIndexPath = self.collectionView.indexPathForItem(at: gesture.location(in: self.collectionView)) else {
    //                break
    //            }
    //            print("selectedIndex", selectedIndexPath.row)
    //            collectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
    //        case UIGestureRecognizerState.changed:
    //            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
    //        case UIGestureRecognizerState.ended:
    //            collectionView.endInteractiveMovement()
    //        default:
    //            collectionView.cancelInteractiveMovement()
    //        }
    //    }

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
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool
    {
        // https://stackoverflow.com/questions/35181940/how-to-add-deselecting-to-uicollectionview-but-without-multiple-selection
        // Default behaviour doesn't allow you to unselect a cell by clicking on it again, changes to allow it
        if (indexPath.row == self.collectionView.numberOfItems(inSection: 0) - 1) {
            return true
        }
        
        // Stop them selecting if there is no excerpt recording happening
        if self.currentExcerpt == nil {
            print("there is nothing being recorded")
            return false
        }
        
        let cell = self.collectionView.cellForItem(at: indexPath)
        if cell?.isSelected == true {
            self.collectionView.deselectItem(at: indexPath, animated: false)
            deselectRow(indexPath: indexPath)
            return false
        }
        
        return true
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
            return
        }
        
        // TEST: while someone is speaking, add another person. Shouldn't be affected because using an array
        
        let cell = self.collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 2.0
        cell?.layer.borderColor = UIColor.gray.cgColor
        guard let name = self.people?[indexPath.row], let startTime = self.recorder?.currentTime else {
            // Double check this
            self.currentPersonSpeaking = nil
            return
        }
        
        self.currentPersonSpeaking = (name: name, startTime: startTime, endTime: nil)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if (indexPath.row == self.collectionView.numberOfItems(inSection: 0) - 1) {
            return
        }
        
        deselectRow(indexPath: indexPath)
        
    }
    
    func deselectRow(indexPath: IndexPath?) {
        // Probably have something that calls endTime either from here if already selected OR directly from the select method, which gets called if you select a different row
        var cell : UICollectionViewCell?
        if let indexPath = indexPath {
            cell = self.collectionView.cellForItem(at: indexPath)
        } else {
            if self.collectionView.indexPathsForSelectedItems?.count != 0, let indexPath = self.collectionView.indexPathsForSelectedItems?[0] {
                cell = self.collectionView.cellForItem(at: indexPath)
            }
        }
        cell?.layer.borderWidth = 0.0
        
        if self.currentPersonSpeaking == nil {
            return
        }
        
        guard let endTime = self.recorder?.currentTime else {
            return
        }
        self.currentPersonSpeaking?.endTime = endTime as TimeInterval
        // ! aaahh
        self.currentExcerpt?.peopleSpeaking.append(self.currentPersonSpeaking! as! (name: String, startTime: TimeInterval, endTime: TimeInterval))
        
        self.currentPersonSpeaking = nil

    }
    
//    public func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
//        if (indexPath.row == self.collectionView.numberOfItems(inSection: 0) - 1) {
//            return false
//        }
//        return true
//    }
//
//    
//    public func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//        print("moving stuff around")
//        // Don't let them move the add people, don't let them add anything to it's place
//        let temp = self.people?.remove(at: sourceIndexPath.item)
//        self.people?.insert(temp!, at: destinationIndexPath.item)
//    }


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
