///
//  AppDelegate.swift
//  gbemu
//
//  Created by Otis Carpay on 09/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Cocoa
import AudioKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: Window!
    
    let queue = DispatchQueue(label: "queue")
    let group = DispatchGroup()
    var gameboy: Gameboy!
    let mixer = AKMixer()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AudioKit.output = mixer
        gameboy = Gameboy(screen: window.emuScreen, queue: queue)
        window.gameboy = gameboy
        try! AudioKit.start()
    }
    
    func loadROM(url: URL) {
        guard let rom = try? Data(contentsOf: url) else { return }
        
        gameboy.reset(withRom: [Byte](rom))
        gameboy.start()
    }
    
    @IBAction func openFile(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedFileTypes = ["gb"]
        dialog.title = "Open ROM file..."
        
        
        dialog.runModal()
        
        
        if let url = dialog.url?.absoluteURL {
            loadROM(url: url)
            NSDocumentController.shared().noteNewRecentDocumentURL(url)
        }
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        loadROM(url: URL(fileURLWithPath: filename))
        return true
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // terminate when the window closes
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true;
    }
}
