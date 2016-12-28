//
//  ROMMenuItem.swift
//  gbemu
//
//  Created by Otis Carpay on 28/12/2016.
//  Copyright © 2016 Otis Carpay. All rights reserved.
//

import Cocoa

class ROMMenuItem: NSMenuItem {
    let path: URL
    let app: AppDelegate
    
    init(to path: URL, app: AppDelegate) {
        self.path = path
        self.app = app
        super.init(title: path.lastPathComponent, action: #selector(startRom(_:)), keyEquivalent: "")
        self.target = self
    }
    
    func startRom(_ sender: NSMenuItem) {
        let rom = [Byte](try! Data(contentsOf: path))
        app.loadROM(rom)
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
