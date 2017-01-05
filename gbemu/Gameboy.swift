//
//  Gameboy.swift
//  gbemu
//
//  Created by Otis Carpay on 11/09/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Dispatch

typealias Byte = UInt8
typealias Word = UInt16
extension UnsignedInteger {
    init(_ bool: Bool) {
        self.init(bool ? 1 : 0)
    }
}

class Gameboy {
    var joypad: Joypad!
    let screen: GPUOutputReceiver
    
    private var stopped = false
    
    var cpu: CPU!
    var gpu: GPU!
    
    let halfFrameTime = 1.0 / 120
    let halfFrameTicks = 1_048_576 / 120
    
    typealias setTimerType = (DispatchTime, @escaping () -> ()) -> ()
    let setTimer: setTimerType
    
    init(screen: GPUOutputReceiver, setTimer: @escaping setTimerType) {
        self.setTimer = setTimer
        self.screen = screen
        
        gpu = GPU(system: self, screen: screen)
        cpu = CPU(system: self) // Can be better?
        joypad = Joypad(system: self)
    }
    
    func reset() {
        gpu = GPU(system: self, screen: screen)
        cpu = CPU(system: self)
    }
    
    func start(withRom rom: [Byte]) {
        cpu.mmu.loadROM(data: rom)
        stopped = false
    }
    
    func stop() {
        stopped = true
    }
    
    var count = 0
    func run() {
        if !stopped {
            let nextTime = DispatchTime.now() + halfFrameTime
            
            while count < halfFrameTicks {
                let m = cpu.step()
                gpu.step(m)
                count += m
            }
            
            count -= halfFrameTicks
            setTimer(nextTime, run)
        }
    }
}
