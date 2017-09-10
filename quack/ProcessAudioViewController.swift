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

        // Think this makes sense. If no recordings were taken or nil, do nothing
        guard let audioExcerpts = self.audioExcerpts, let mainAudioFileLocation = self.mainAudioFileLocation, let filename = self.filename else {
            finishedProcessing()
            return
        }
        
        self.excerptCounter = audioExcerpts.count
        self.totalExcerpts = audioExcerpts.count
        self.label.text = "Processing \(self.excerptCounter) audio files"
        
        for excerpt in audioExcerpts {
//            print("excerpt", excerpt)
            excerpt.trimAudio(url: mainAudioFileLocation, name: filename, reference: self)
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
//        deleteAudioExcerpts()
    }
    
    func deleteAudioExcerpts() {
        guard let audioExcerpts = self.audioExcerpts else {
            finishedProcessing()
            return
        }
        
        for excerpt in audioExcerpts {
            AudioManager.sharedInstance.deleteAudioFile(url: excerpt.trimmedUrl)
        }
        finishedProcessing()
    }
    
    func finishedProcessing() {
        self.label.text = "Finished processing"
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.view.removeFromSuperview()
            self.delegate?.reset()
        })
    }
}
