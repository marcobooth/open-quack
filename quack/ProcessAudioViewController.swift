//
//  ProcessAudioViewController.swift
//  quack
//
//  Created by Marco Booth on 08/09/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import UIKit

class ProcessAudioViewController: UIViewController {

    var excerptCounter : Int = 0
    var totalExcerpts : Int = 0
    var audioExcerpts : [AudioExcerpt]?
    var mainAudioFileLocation : URL?
    var filename : String?
    // should this be a protocol?
    var delegate : RecordingViewController?
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: What if the count is 0

        self.excerptCounter = (self.audioExcerpts?.count)!
        self.totalExcerpts = (self.audioExcerpts?.count)!
        self.label.text = "Processing \(self.excerptCounter) audio files"
        
        for excerpt in self.audioExcerpts! {
            print("excerpt", excerpt)
            excerpt.trimAudio(url: self.mainAudioFileLocation!, name: self.filename!, reference: self)
        }
    }
    
    func trimmedExcerpt(success : Bool) {
        DispatchQueue.main.async {
            self.excerptCounter -= 1
            self.label.text = "Processing \(self.excerptCounter) audio files"
            let progress : Float = self.progressView.progress + (1.0 / Float(self.totalExcerpts))
            self.progressView.setProgress(progress, animated: false)
            
            if self.excerptCounter == 0 {
                self.sendPostRequest()
            }
        }
    }
    
    func sendPostRequest() {
        deleteAudioExcerpts()
    }
    
    func deleteFile(url : URL?) {
        guard let fileToDelete = url else {
            print("file was not deleted")
            return
        }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: fileToDelete)
        } catch {
            print(error)
        }
    }
    
    func deleteAudioExcerpts() {
        for excerpt in self.audioExcerpts! {
            deleteFile(url: excerpt.trimmedUrl)
        }
        deleteFile(url: self.mainAudioFileLocation)
        finishedProcessing()
    }
    
    func finishedProcessing() {
        // Just for testing so i can see the UI
        self.label.text = "Finished processing"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.view.removeFromSuperview()
            print("removed from superview")
            self.delegate?.reset()
        })
    }
}
