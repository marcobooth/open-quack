//
//  ProcessAudioViewController.swift
//  quack
//
//  Created by Marco Booth on 08/09/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import UIKit
import Alamofire

class ProcessAudioViewController: UIViewController {
    var totalExcerpts : Int = 0
    var excerptsTrimmed : Int = 0
    
    var audioExcerpts : [AudioExcerpt]?
    var mainAudioFileLocation : URL?
    var eventName : String?
    // should this be a protocol?
    var delegate : RecordingViewController?
    
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Think this makes sense. If no recordings were taken or nil, do nothing
        guard let audioExcerpts = self.audioExcerpts, audioExcerpts.count > 0, let mainAudioFileLocation = self.mainAudioFileLocation, let eventName = self.eventName else {
            finishedProcessing()
            return
        }
        
        self.totalExcerpts = audioExcerpts.count
        self.label.text = "Processing \(self.totalExcerpts) audio files"
        
        for excerpt in audioExcerpts {
            excerpt.trimAudio(url: mainAudioFileLocation, name: eventName, reference: self)
        }
    }
    
    func trimmedExcerpt(success : Bool) {
        DispatchQueue.main.async {
            self.excerptsTrimmed += 1
            self.label.text = "Processing \(self.totalExcerpts - self.excerptsTrimmed) audio files"

            let progress : Float = self.progressView.progress + (1.0 / Float(self.totalExcerpts))
            self.progressView.setProgress(progress, animated: false)
            
            if self.excerptsTrimmed == self.totalExcerpts {
                self.sendMetadata()
            }
        }
    }
    
    func sendMetadata() {
        guard let audioExcerpts = self.audioExcerpts else { return }
        
        var jsonExerpts = [Parameters]()
        for excerpt in audioExcerpts {
            jsonExerpts.append(excerpt.toJSON())
        }
        
        let parameters: Parameters = [
            "name": self.eventName ?? "Unknown",
            "excerpts": jsonExerpts,
        ]
        
        // Both calls are equivalent
        Alamofire.request("http://localhost:4246/quack/metadata", method: .post, parameters: parameters, encoding: JSONEncoding.default).response { response in
            DispatchQueue.main.async {
                self.sendAudioExcerpts()
            }
        }
    }
    
    func sendAudioExcerpts() {
        var uploadedExcerpts = 0
        
        self.label.text = "Sending \(self.totalExcerpts - uploadedExcerpts) audio files to server"
        
        if let audioExcerpts = self.audioExcerpts {
            for excerpt in audioExcerpts {
                guard let trimmedUrl = excerpt.trimmedUrl, let trimmedFilename = excerpt.trimmedFilename else { return }
                
                print("Uploading:", trimmedFilename)
                
                guard let encodedFilename = trimmedFilename.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
                    return
                }
                let uploadUrl = "http://localhost:4246/quack/excerpt/\(encodedFilename)"
                
                Alamofire.upload(trimmedUrl, to: uploadUrl).responseJSON { response in
                    print("done with \(trimmedFilename)")
                    uploadedExcerpts += 1
                    
                    self.label.text = "Sending \(self.totalExcerpts - uploadedExcerpts) audio files to server"
                    
                    if uploadedExcerpts == self.totalExcerpts {
                        self.deleteAudioExcerpts()
                    }
                }
            }
        }
    }
    
    func deleteAudioExcerpts() {
        if let audioExcerpts = self.audioExcerpts {
            for excerpt in audioExcerpts {
                AudioManager.deleteAudioFile(url: excerpt.trimmedUrl)
            }
        }
        
        finishedProcessing()
    }
    
    func finishedProcessing() {
        self.label.text = "Finished processing"

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.view.removeFromSuperview()
            self.delegate?.deleteAndUnwind()
        })
    }
}
