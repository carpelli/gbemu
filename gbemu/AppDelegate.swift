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

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        let data = NSData(contentsOfFile: NSBundle.mainBundle().pathForResource("ttt", ofType: "gb")!)
        var rom = [Byte](count: 0x8000, repeatedValue: 0)
        data?.getBytes(&rom, length: 0x8000)
        
        let gameboy = Gameboy(screen: view, joypadInput: window)
        gameboy.start(withRom: rom)
        gameboy.gameLoop(500)
        NSThread.detachNewThreadSelector(Selector("gameLoop:"), toTarget: gameboy, withObject: nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

