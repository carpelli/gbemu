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
    
    override func keyDown(theEvent: NSEvent) {
        fatalError()
        
        if let button = buttonForCode(theEvent.keyCode) {
            joypad?.buttonDown(button)
        }
    }
    
    override func keyUp(theEvent: NSEvent) {
        if let button = buttonForCode(theEvent.keyCode) {
            joypad?.buttonUp(button)
        }
    }
    
    private func buttonForCode(keyCode: UInt16) -> Joypad.Button? {
        switch keyCode {
            case   7: return .A
            case   6: return .B
            case  49: return .Select
            case  36: return .Start
            case 124: return .Right
            case 123: return .Left
            case 126: return .Up
            case 125: return .Down
            default:  return nil
        }
    }
    
    func connectToJoypad(joypad: Joypad) {
        self.joypad = joypad
    }
}