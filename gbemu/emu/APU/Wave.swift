//
//  Wave.swift
//  gbemu
//
//  Created by Otis Carpay on 29/12/2018.
//  Copyright © 2018 Otis Carpay. All rights reserved.
//

import Cocoa

class Wave: Channel {
    var dacPower = 0
    
    init() {
        super.init(wave: [Double](repeating: 0, count: 32), length: 32, multiplier: 2, hasEnvelope: false)
    }
    
    override func trigger() {
        super.trigger()
        wavePointer = 0
    }
    
    override func writeByte(register: Int, value: Byte) {
        switch register {
        case 0:
            enabled = value.hasBit(7)
        case 1:
            timer = 256 - Int(value)
        case 2:
            switch value >> 5 & 3 {
                case 0: volume = 0
                case 1: volume = 1
                case 2: volume = 0.5
                case 3: volume = 0.25
                default: break
            }
        default:
            super.writeByte(register: register, value: value)
        }
    }
    
    func writeWaveTable(register: Int, value: Byte) {
        wave[register * 2] = Double(value >> 4) / 15
        wave[register * 2 + 1] = Double(value & 0xF) / 15
    }
}
