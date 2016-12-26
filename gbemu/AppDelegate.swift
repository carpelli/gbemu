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
        // Insert code here to initialize your applicationlet data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "opus5", ofType: "gb")!))
        var rom = [Byte](repeating: 0, count: 0x8000)
        (data as NSData?)?.getBytes(&rom, length: 0x8000)
        
        let gameboy = Gameboy(screen: view, joypadInput: window)
        gameboy.start(withRom: rom)
        
        let queue = OperationQueue()
        queue.addOperation(gameboy.run)
//        gameboy.run(times: 1)
        //Thread.detachNewThreadSelector(Selector("gameLoop:"), toTarget: gameboy, with: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

