//
//  Gameboy.swift
//  gbemu
//
//  Created by Otis Carpay on 11/09/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Dispatch
import AudioKit

typealias Byte = UInt8
typealias Word = UInt16
extension UnsignedInteger {
    init(_ bool: Bool) {
        self.init(bool ? 1 : 0)
    }
}
extension Byte {
    func hasBit(_ bit: Byte) -> Bool {
        return self & 1 << bit > 0
    }
}

final class Gameboy {
    var joypad: Joypad!
    let screen: GPUOutputReceiver
    
    private(set) public var stopped = false
    private var inactive = true //Whether there is no thread running
    let queue: DispatchQueue
    
    var cpu: CPU!
    var gpu: GPU!
    var sound = Sound()
    
    private let halfFrameTime = 1.0 / 120
    private let halfFrameTicks = 1_048_576 / 120
    
    init(screen: GPUOutputReceiver, queue: DispatchQueue) {
        self.screen = screen
        self.queue = queue
        gpu = GPU(system: self, screen: screen)
        cpu = CPU(system: self) // Can be better?
        joypad = Joypad(system: self)
    }
    
    func reset(withRom rom: [Byte]) {
        stop()
        while (!inactive) { usleep(1000) } //can this be better?
        
        print("\nReset-----------")
        gpu = GPU(system: self, screen: screen)
        cpu = CPU(system: self)
        sound = Sound()
        
        cpu.mmu.loadROM(data: rom)
    }
    
    func start() {
        if inactive {
            stopped = false
            run()
        }
    }
    
    func stop() {
        stopped = true
    }
    
    var count = 0
    
    private func run() {
        if !stopped {
            inactive = false
            let nextTime = DispatchTime.now() + halfFrameTime
            
            while count < halfFrameTicks {
                let m = cpu.step()
                gpu.step(m)
                sound.step(m)
                count += m
            }
            
            count -= halfFrameTicks
            
            self.queue.asyncAfter(deadline: nextTime, execute: run)
        } else {
            inactive = true
        }
    }
}
