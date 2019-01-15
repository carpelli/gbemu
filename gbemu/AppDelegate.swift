///
//  AppDelegate.swift
//  gbemu
//
//  Created by Otis Carpay on 09/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Cocoa
import SpriteKit
import QuartzCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: Window!
    @IBOutlet weak var panel: Panel!
    @IBOutlet weak var view: SKView!
    
    let player = AudioPlayer()
    var displayLink: CVDisplayLink?
    
    var gameboy: Gameboy!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        window.makeFirstResponder(window)
//        print(window.firstResponder)
        window.aspectRatio = NSSize(width: 160, height: 144)
    }
    
    func loadROM(url: URL) {
        let scene = Scene()
        
        gameboy = Gameboy(screen: scene)
        window.gameboy = gameboy
        guard let rom = try? Data(contentsOf: url) else { return }
        gameboy.reset(withRom: [Byte](rom))
        self.player.start(with: self.gameboy.apu)
        panel.apu = gameboy.apu

        scene.gameboy = gameboy
        view.showsFPS = true
        view.showsNodeCount = true
        view.presentScene(scene)
        window.makeFirstResponder(window)
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
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        }
    }
    
    @IBAction func togglePanel(_ sender: Any) {
        if panel.isVisible {
            panel.close()
        } else {
            panel.makeKeyAndOrderFront(sender)
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

func dumpDebug(fileName: String, content: String) {
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        
        let fileURL = dir.appendingPathComponent(fileName)
        
        //writing
        do {
            try content.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {/* error handling here */}
    }
}

//        let callback: CVDisplayLinkOutputCallback = { (
//                displayLink: CVDisplayLink,
//                inNow: UnsafePointer<CVTimeStamp>,
//                inOutputTime: UnsafePointer<CVTimeStamp>,
//                flagsIn: CVOptionFlags,
//                flagsOut: UnsafeMutablePointer<CVOptionFlags>,
//                displayLinkContext: UnsafeMutableRawPointer?
//            ) -> CVReturn in
//            let app = Unmanaged<AppDelegate>.fromOpaque(displayLinkContext!).takeUnretainedValue()
//            app.gameboy.runFrame()
//            app.window!.emuScreen.drawView()
//            return kCVReturnSuccess
//        }
//        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
//        CVDisplayLinkSetOutputCallback(
//            displayLink!,
//            callback,
//            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
//        )
//        CVDisplayLinkStart(displayLink!)
