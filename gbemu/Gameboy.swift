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
    let joypad: Joypad
    let screen: GPUOutputReceiver
    
    private var stopped = false
    
    var cpu: CPU!
    var gpu: GPU!
    
    init(screen: GPUOutputReceiver, joypadInput: JoypadInput) {
        joypad = Joypad(input: joypadInput)
        self.screen = screen
        gpu = GPU(system: self, screen: screen)
        cpu = CPU(system: self) // Can be better
    }
    
    func reset() {
        gpu = GPU(system: self, screen: screen)
        cpu = CPU(system: self)
    }
    
    func start(withRom rom: [Byte]) {
        cpu.mmu.load(rom)
        stopped = false
    }
    
    func stop() {
        stopped = true
    }
    
    func run() {
        while !stopped {
            cpu.step()
        }
    }
    
    func run(times: Int) {
        for _ in 1...times {
            cpu.step()
        }
    }
}
