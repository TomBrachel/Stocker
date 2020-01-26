//
//  Message.swift
//  Stock Trailer
//
//  Created by תום ברכל on /0209/2018.
//  Copyright © 2018 Tom Brachel. All rights reserved.
//

import Foundation

class Message {
    var site: String
    var type: String
    var text: String
    var link: String
    var time: Date
    
    init(site: String, type: String, text: String, link: String, time: Date) {
        self.site = site
        self.type = type
        self.text = text
        self.link = link
        self.time = time
    }
}
