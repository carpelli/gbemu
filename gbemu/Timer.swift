//
//  Timer.swift
//  gbemu
//
//  Created by Otis Carpay on 28/12/2016.
//  Copyright © 2016 Otis Carpay. All rights reserved.
//

final class Timer {
    let system: Gameboy // YES????
    
    var divider: Byte = 0 //FF04
    var counter: Byte = 0 //FF05
    var modulo: Byte  = 0 //FF06
    var control: Byte = 0 //FF07
    
    private var internalDiv: Int = 0
    private var internalCount: Int = 0
    
    var speed: Int { return Int(control) & 0b11 }
    var enabled: Bool { return control & 0b100 > 0 }
    
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
            
            var threshold = 0
            switch speed {
                case 0: threshold = 256
                case 1: threshold = 4
                case 2: threshold = 16
                case 3: threshold = 64
                default: break
            }
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
}
