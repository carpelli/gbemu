//
//  Window.swift
//  gbemu
//
//  Created by Otis Carpay on 09/09/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Cocoa

class Window: NSWindow, JoypadInput {
    weak var joypad: Joypad?
    
    override func keyDown(with theEvent: NSEvent) {
        if let button = buttonForCode(theEvent.keyCode) {
            joypad?.buttonDown(button)
        }
    }
    
    override func keyUp(with theEvent: NSEvent) {
        if let button = buttonForCode(theEvent.keyCode) {
            joypad?.buttonUp(button)
        }
    }
    
    private func buttonForCode(_ keyCode: UInt16) -> Joypad.Button? {
        switch keyCode {
            case   7: return .a
            case   6: return .b
            case  49: return .select
            case  36: return .start
            case 124: return .right
            case 123: return .left
            case 126: return .up
            case 125: return .down
            default:  return nil
        }
    }
    
    func connectToJoypad(_ joypad: Joypad) {
        self.joypad = joypad
    }
}
