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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let data = NSDataAsset(name: "tetris")!.data
        let rom = [Byte](data)
        
        let gameboy = Gameboy(screen: view, joypadInput: window)
        gameboy.start(withRom: rom)
        
        let queue = OperationQueue()
        queue.addOperation({ gameboy.run() })
//        gameboy.run(times: 1)
        //Thread.detachNewThreadSelector(Selector("gameLoop:"), toTarget: gameboy, with: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

