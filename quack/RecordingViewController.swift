//
//  RecordingViewController.swift
//  quack
//
//  Created by Marco Booth on 31/08/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingViewController: UIViewController {
    var recorder : AVAudioRecorder?
    var recordingFileLocation : URL?
    var people : [String]? = ["Jerome", "Jeff"]
    var audioExcerpts = [AudioExcerpt]()
    var currentExcerpt : AudioExcerpt?
    var currentPersonSpeaking : (name: String, startTime: TimeInterval, endTime: TimeInterval?)?
    var lightBorder : Bool = false
    
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var recordButton : UIButton!
    @IBOutlet weak var noteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setSessionRecord()
        self.recordWithPermission()
        
        self.noteButton.isEnabled = false
    }
    
    @IBAction func stopEvent(_ sender: UIBarButtonItem) {
        if self.currentExcerpt != nil {
            self.showErrorMessage(title: "Error", message: "You cannot end an event while recording an excerpt")
            return
        }
        
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
            print("sendToServer is true")
            for excerpt in self.audioExcerpts {
                print("doing an excerpt")
                excerpt.trimAudio(url: recordingFileLocation!, name: self.title!)
            }
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
                print("Permission to record not granted")
                DispatchQueue.main.async {
                    self.stopRecording(sendToServer: false)
                    return
                }
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
            self.noteButton.isEnabled = true
            self.currentExcerpt = AudioExcerpt(startTime: currentTime, timeDifference: 30.0)
            self.recordButton.setImage(#imageLiteral(resourceName: "square"), for: .normal)
            self.recordButton.setTitle("Stop Recording", for: .normal)
            self.lightBorder = true
            self.collectionView.reloadData()
        } else {
            self.lightBorder = false
            self.collectionView.reloadData()
            stopExcerpt()
        }
    }
    
    func stopExcerpt() {
        guard let currentTime = self.recorder?.currentTime else {
            print("no recorder, no time")
            return
        }
        
        self.noteButton.isEnabled = false
        
        if self.currentPersonSpeaking != nil {
            self.deselectRow(indexPath: nil)
        }
        
        self.currentExcerpt?.endTime = currentTime
        // Feel like this ! might be ok, maybe should remove it though
        self.audioExcerpts.append(self.currentExcerpt!)
        self.currentExcerpt = nil
        self.recordButton.setImage(#imageLiteral(resourceName: "record"), for: .normal)
    }
    
    func setupRecorder() {
        let currentFilename : String
        if let title = self.title {
            currentFilename = title + ".wav"
        } else {
            print("error: unNamed event, we gots a problem")
            self.stopRecordingAlert(message: "Please provide a name for this event.")
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.recordingFileLocation = documentsDirectory.appendingPathComponent(currentFilename)
        
        guard let recordingLocation = self.recordingFileLocation else {
            return
        }
        print("writing to soundfile url: '\(recordingLocation)'")

        // Add this as a pull request from where I got the code,
        // https://stackoverflow.com/questions/9303875/fileexistsatpath-returning-no-for-files-that-exist
        if FileManager.default.fileExists(atPath: recordingLocation.path) {
            // TEST: same file name
            self.stopRecordingAlert(message: "Please provide a unique name for this event. The name you have provided is already in use")
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
    
    @IBAction func addNote(_ sender: UIButton) {
        let alert = textFieldAlert(name: "Add a note", message: "A message will be attached with this recording")
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: {action in
            guard let note = alert.textFields?[0].text, let currentTime = self.recorder?.currentTime else {
                return
            }
            self.currentExcerpt?.notes.append((note: note, time: currentTime))
        }))
        self.present(alert, animated:true, completion:nil)
        return
    }
}

// MARK: AVAudioRecorderDelegate
extension RecordingViewController : AVAudioRecorderDelegate {
    
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

extension RecordingViewController : UICollectionViewDataSource, UICollectionViewDelegate {
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
        
        cell.layer.borderColor = UIColor.gray.cgColor
        if self.lightBorder == true {
            cell.layer.borderWidth = 0.5
        } else {
            cell.layer.borderWidth = 0.0
        }
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
        
        cell?.layer.borderWidth = 0.5
        
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
    
}

extension RecordingViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let height = self.view.frame.size.height
        let width = self.view.frame.size.width
        
        return CGSize(width: width*0.45, height: height*0.2)
    }
}

extension RecordingViewController {
    func textFieldAlert(name: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: name, message: message, preferredStyle: .alert)
        alert.addTextField(configurationHandler: nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {action in
            print("cancel was tapped")
        }))
        
        return alert
    }
    
    func stopRecordingAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: {action in
            self.stopRecording(sendToServer: false)
        }))
        self.present(alert, animated:true, completion:nil)
    }
}
