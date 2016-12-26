//
//  Gameboy.swift
//  gbemu
//
//  Created by Otis Carpay on 11/09/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Cocoa

typealias Byte = UInt8
typealias Word = UInt16
extension UnsignedInteger {
    init(_ bool: Bool) {
        self.init(bool ? 1 : 0)
    }
}

class Gameboy {
    var cpu: CPU!
    var gpu: GPU!
    let joypad: Joypad
    var window: Window!
    
    init(screen: GPUOutputReceiver, joypadInput: JoypadInput) {
        joypad = Joypad(input: joypadInput)
        gpu = GPU(system: self, screen: screen)
        cpu = CPU(system: self) // Can be better
    }
    
    func start(withRom rom: [Byte]) {
        cpu.mmu.load(rom)
    }
    
    func run() {
        cpu.runFrame()
    }
    
    func run(times: Int) {
        for _ in 1...times {
            cpu.runFrame()
        }
    }
}
