//
//  Window.swift
//  gbemu
//
//  Created by Otis Carpay on 09/09/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Cocoa
import AudioKit
import Carbon.HIToolbox.Events

class Window: NSWindow {
    
    @IBOutlet weak var emuScreen: Screen!
    
    weak var gameboy: Gameboy?
    
    override func keyDown(with theEvent: NSEvent) {
        if let button = buttonForCode(Int(theEvent.keyCode)) {
            gameboy?.joypad.buttonDown(button)
        }
    }
    
    override func keyUp(with theEvent: NSEvent) {
        switch Int(theEvent.keyCode) {
            case kVK_Escape: NSApplication.shared().terminate(self)
            case kVK_ANSI_P: togglePause()
            case let keyCode:
                if let button = buttonForCode(keyCode) {
                    gameboy?.joypad.buttonUp(button)
                }
        }
    }
    
    private func togglePause() {
        guard let gameboy = gameboy else { return }
        
        if gameboy.stopped {
            (AudioKit.output as? AKMixer)?.volume = 1
            gameboy.start()
        } else {
            gameboy.stop()
            (AudioKit.output as? AKMixer)?.volume = 0
        }
    }
    
    private func buttonForCode(_ keyCode: Int) -> Joypad.Button? {
        switch keyCode {
            case   7: return .a
            case   6: return .b
            case  36: return .start
            case  49: return .select
            case 123: return .left
            case 124: return .right
            case 125: return .down
            case 126: return .up
            default:  return nil
        }
    }
}
