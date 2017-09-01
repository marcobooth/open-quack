//
//  AudioExcerpt.swift
//  quack
//
//  Created by Marco Booth on 31/08/2017.
//  Copyright © 2017 Marco Booth. All rights reserved.
//

import Foundation

struct AudioExcerpt {
    
    var startTime : TimeInterval
    var endTime : TimeInterval?
    var trimmedUrl : URL?
    var peopleSpeaking = [(name: String, startTime: TimeInterval, endTime: TimeInterval)]()
    var notes = [(note: String, time: TimeInterval)]()
    
    init(startTime: TimeInterval) {
        self.startTime = startTime
    }
    
    func trimAudio(url: URL) {
        
    }
    
    func sendToServer() {
        
    }
}
