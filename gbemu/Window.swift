//
//  Window.swift
//  gbemu
//
//  Created by Otis Carpay on 09/09/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Cocoa

class Window: NSWindow {
    
    @IBOutlet weak var emuScreen: Screen!
    
    weak var joypad: Joypad?
    
    override func keyDown(with theEvent: NSEvent) {
        if let button = buttonForCode(theEvent.keyCode) {
            joypad?.buttonDown(button)
        }
    }
    
    override func keyUp(with theEvent: NSEvent) {
        if theEvent.keyCode == 53 { NSApplication.shared().terminate(self) }
        if let button = buttonForCode(theEvent.keyCode) {
            joypad?.buttonUp(button)
        }
    }
    
    private func buttonForCode(_ keyCode: UInt16) -> Joypad.Button? {
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
