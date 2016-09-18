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
extension UnsignedIntegerType {
    init(_ bool: Bool) {
        self.init(bool ? 1 : 0)
    }
}

class Gameboy {
    var cpu: CPU!
    let gpu: GPU
    let joypad: Joypad
    var window: Window!
    
    init(screen: GPUOutputReceiver, joypadInput: JoypadInput) {
        gpu = GPU(screen: screen)
        joypad = Joypad(input: joypadInput)
        cpu = CPU(system: self)
    }
    
    func start(withRom rom: [Byte]) {
        cpu.mmu.load(rom)
        cpu.reg.pc = 0x100
    }
    
    func gameLoop(times: Int) {
        var i = 0
        while i++ < times {
            cpu.runFrame()
        }
    }
}