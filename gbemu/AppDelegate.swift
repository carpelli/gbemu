///
//  AppDelegate.swift
//  gbemu
//
//  Created by Otis Carpay on 09/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: Window!
    @IBOutlet weak var view: ScreenView!
    @IBOutlet weak var romList: NSMenu!
    
    let queue = OperationQueue()
    var gameboy: Gameboy!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        gameboy = Gameboy(screen: view, joypadInput: window)
        
        for url in Bundle.main.urls(forResourcesWithExtension: "gb", subdirectory: nil)! {
            romList.addItem(ROMMenuItem(to: url, app: self))
        }
    }
    
    func loadROM(_ rom: [Byte]) {
        gameboy.stop()
        queue.waitUntilAllOperationsAreFinished()
        gameboy.reset()
        gameboy.start(withRom: rom)
        queue.addOperation(gameboy.run)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
