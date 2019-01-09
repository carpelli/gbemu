//
//  Panel.swift
//  gbemu
//
//  Created by Otis Carpay on 23/12/2018.
//  Copyright © 2018 Otis Carpay. All rights reserved.
//

import Cocoa

class Panel: NSPanel {
    
    weak var apu: APU?
    
    @IBOutlet weak var checkCh1: NSButton!
    @IBOutlet weak var checkCh2: NSButton!
    @IBOutlet weak var checkWave: NSButton!
    @IBOutlet weak var checkNoise: NSButton!
    
    @IBAction func check(_ sender: NSButton) {
        print(sender.tag)
        print(apu != nil)
        if let channel = Channel.Which(rawValue: sender.tag) {
            apu?.toggleChannel(channel)
        }
    }
}
