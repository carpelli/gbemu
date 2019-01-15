//
//  Timer.swift
//  gbemu
//
//  Created by Otis Carpay on 28/12/2016.
//  Copyright © 2016 Otis Carpay. All rights reserved.
//

final class Timer {
    let system: Gameboy // YES????
    
    var divider: Byte = 0   //FF04
    var counter: Byte = 0   //FF05
    var modulo: Byte = 0    //FF06
    var control: Byte = 0 { //FF07
        didSet {
            switch control & 0b11 {
                case 0: threshold = 256
                case 1: threshold = 4
                case 2: threshold = 16
                case 3: threshold = 64
                default: break
            }
            enabled = control.hasBit(2)
        }
    }
    
    var threshold = 64
    var enabled = true
            
    private var internalDiv: Int = 0
    private var internalCount: Int = 0
    
    init(system: Gameboy) {
        self.system = system
    }
    
    func increment(_ m: Int) {
        internalDiv += m
        if internalDiv >= 64 {
            divider = divider &+ 1
            internalDiv -= 64
        }
        
        if enabled {
            internalCount += m
            
            while internalCount >= threshold {
                internalCount -= threshold
                counter = counter &+ 1
                if counter == 0 {
                    counter = modulo
                    system.cpu.requestInterrupt(.timer)
                }
            }
        }
    }
    
    func readByte(_ address: Int) -> Byte {
        switch address {
            case 0xFF04: return divider
            case 0xFF05: return counter
            case 0xFF06: return modulo
            case 0xFF07: return control | 0xF8
        default: fatalError()
        }
    }
    
    func writeByte(_ address: Int, value: Byte) {
        switch address {
            case 0xFF04: (divider, internalCount) = (0, 0)
            case 0xFF05: counter = value
            case 0xFF06: modulo = value
            case 0xFF07: control = value
            default: fatalError()
        }
    }
}
