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
    @IBOutlet weak var romList: NSMenu!
    
    let queue = DispatchQueue(label: "queue")
    let group = DispatchGroup()
    var gameboy: Gameboy!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for url in Bundle.main.urls(forResourcesWithExtension: "gb", subdirectory: nil)! {
            romList.addItem(ROMMenuItem(to: url, app: self))
        }
        gameboy = Gameboy(screen: window.emuScreen) {
            self.queue.asyncAfter(deadline: $0, execute: $1)
        }
        window.joypad = gameboy.joypad
    }
    
    func loadROM(_ rom: [Byte]) {
        gameboy.stop()
        usleep(20000) //Fixme
        gameboy.reset()
        gameboy.start(withRom: rom)
        gameboy.run()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // terminate when the window closes
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true;
    }
}
