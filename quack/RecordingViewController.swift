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
    var peopleInMeeting : [String] = []
    var audioExcerpts = [AudioExcerpt]()
    var currentExcerpt : AudioExcerpt?
    var currentPersonSpeaking : (name: String, startTime: TimeInterval, endTime: TimeInterval?)?
    var lightBorder : Bool = false
    
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var recordButton : UIButton!
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var recordingIndicatorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.noteButton.isEnabled = false
        self.recordingIndicatorLabel.text = "Currently listening"
        
        AudioManager.setSessionRecord()

        AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] granted in
            if granted {
                DispatchQueue.main.async {
                    self.startRecording()
                    
                }
            } else {
                DispatchQueue.main.async {
                    self.stopRecording(sendToServer: false)
                }
            }
        }
        
        if AVAudioSession.sharedInstance().recordPermission() == .denied {
            self.stopRecording(sendToServer: false)
        }
    }
    
    // MARK: utilities
    
    func startRecording() {
        guard let title = self.title else {
            self.stopRecordingAlert(message: "Please provide a name for this event.")
            return
        }
        let currentFilename = title + ".wav"
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.recordingFileLocation = documentsDirectory.appendingPathComponent(currentFilename)
        
        guard let recordingLocation = self.recordingFileLocation else {
            self.stopRecordingAlert(message: "Could not set up location to save file")
            return
        }
        print("writing to soundfile url: '\(recordingLocation)'")
        
        // https://stackoverflow.com/questions/9303875/fileexistsatpath-returning-no-for-files-that-exist
        if FileManager.default.fileExists(atPath: recordingLocation.path) {
            self.stopRecordingAlert(message: "Please provide a unique name for this event. The name you have provided is already in use.")
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
            
            // creates/overwrites the file at soundFileURL
            self.recorder?.prepareToRecord()

            self.recorder?.record()
        } catch {
            print(error.localizedDescription)
            
            self.recorder = nil
            self.stopRecordingAlert(message: "Could not start recording. Please try to start the event again")
        }
    }
    
    func stopRecording(sendToServer: Bool) {
        if self.currentExcerpt != nil {
            self.stopExcerpt()
        }
        
        self.recorder?.stop()
        AudioManager.unsetSessionRecord()
        self.recorder = nil
        
        if sendToServer == true, let title = self.title,
            let processingVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "progress") as? ProcessAudioViewController {
            // begin processing - maybe should disable view while in processing..?
            processingVC.modalPresentationStyle = .overCurrentContext
            processingVC.audioExcerpts = self.audioExcerpts
            processingVC.eventName = title
            processingVC.delegate = self
            processingVC.mainAudioFileLocation = self.recordingFileLocation
            
            self.present(processingVC, animated: true, completion: nil)
        } else {
            self.deleteAndUnwind()
        }
    }
    
    func deleteAndUnwind() {
        AudioManager.deleteAudioFile(url: self.recordingFileLocation)
        self.performSegue(withIdentifier: "unwindToStart", sender: nil)
    }
    
    func stopExcerpt() {
        guard let currentTime = self.recorder?.currentTime, let currentExcerpt = self.currentExcerpt else {
            print("no recorder, no time")
            return
        }
        
        self.recordingIndicatorLabel.text = "Currently listening"
        self.noteButton.isEnabled = false
        
        if self.currentPersonSpeaking != nil {
            self.deselectRow(indexPath: nil)
            self.currentPersonSpeaking = nil
        }
        
        currentExcerpt.endTime = currentTime
        self.audioExcerpts.append(currentExcerpt)
        self.currentExcerpt = nil
        self.recordButton.setImage(#imageLiteral(resourceName: "record"), for: .normal)
    }
    
    // MARK: IBActions
    
    @IBAction func stopEvent(_ sender: UIBarButtonItem) {
        if self.currentExcerpt != nil {
            self.showErrorMessage(title: "Error", message: "You cannot end an event while recording an excerpt.")
            return
        }
        
        let alert = UIAlertController(title: "End event", message: "Please confirm that you would like the event to end", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { action in
            self.stopRecording(sendToServer: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func createOrStopExcerpt(_ sender: UIButton) {
        guard let currentTime = self.recorder?.currentTime else {
            print("no recorder, no time")
            return
        }
        
        if self.currentExcerpt == nil {
            self.noteButton.isEnabled = true
            self.currentExcerpt = AudioExcerpt(startTime: currentTime, timeDifference: 30.0)
            self.recordButton.setImage(#imageLiteral(resourceName: "square"), for: .normal)
            self.recordingIndicatorLabel.text = "Recording (includes last 30 seconds)"
            self.lightBorder = true
            self.collectionView.reloadData()
        } else {
            self.lightBorder = false
            self.collectionView.reloadData()
            
            stopExcerpt()
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
        self.present(alert, animated: true, completion: nil)
    }
}

extension RecordingViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // The 1 is the extra cell used for adding additional people to the collection
        return 1 + self.peopleInMeeting.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (indexPath.row == self.collectionView.numberOfItems(inSection: 0) - 1) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: "add", for: indexPath)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "person", for: indexPath) as! PersonCollectionViewCell
        cell.name.text = peopleInMeeting[indexPath.row]
        
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
            let alert = textFieldAlert(name: "Add a person", message: "Add a person to the list of participants")
            alert.addAction(UIAlertAction(title: "Add", style: .default, handler: {action in
                guard let name = alert.textFields?[0].text else { return }
                
                self.peopleInMeeting.append(name)
                self.collectionView.reloadData()
            }))

            self.present(alert, animated:true, completion:nil)
        } else {
            guard let startTime = self.recorder?.currentTime else { return }
            
            let name = self.peopleInMeeting[indexPath.row]
            self.currentPersonSpeaking = (name: name, startTime: startTime, endTime: nil)
            
            let cell = self.collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 2.0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if (indexPath.row == self.collectionView.numberOfItems(inSection: 0) - 1) {
            return
        }
        
        deselectRow(indexPath: indexPath)
    }
    
    func deselectRow(indexPath: IndexPath?) {
        var cell : UICollectionViewCell?
        if let indexPath = indexPath {
            cell = self.collectionView.cellForItem(at: indexPath)
        } else if self.collectionView.indexPathsForSelectedItems?.count != 0, let indexPath = self.collectionView.indexPathsForSelectedItems?[0] {
            cell = self.collectionView.cellForItem(at: indexPath)
        } else {
            return
        }
        
        cell?.layer.borderWidth = 0.5
        
        if self.currentPersonSpeaking == nil {
            return
        }
        
        guard let endTime = self.recorder?.currentTime, let currentPersonSpeaking = self.currentPersonSpeaking else {
            return
        }
        
        self.currentExcerpt?.peopleSpeaking.append((name: currentPersonSpeaking.name, startTime: currentPersonSpeaking.startTime, endTime: endTime as TimeInterval))
        
        self.currentPersonSpeaking = nil
    }
    
}

extension RecordingViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.view.frame.size.height
        let width = self.view.frame.size.width
        
        return CGSize(width: width * 0.45, height: height * 0.2)
    }
}

extension RecordingViewController {    
    func stopRecordingAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { action in
            self.stopRecording(sendToServer: false)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension RecordingViewController : AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("audioRecorderDidFinishRecording")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let e = error {
            print("\(e.localizedDescription)")
        }
    }
}

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
