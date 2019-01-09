//
//  Noise.swift
//  gbemu
//
//  Created by Otis Carpay on 09/01/2019.
//  Copyright © 2019 Otis Carpay. All rights reserved.
//
import Cocoa

class Noise: Channel {
    var lfsr: Word = 0 // the 15-bit linear feedback shift register
    var shortMode = false // if true then lfsr is 7-bit
    
    init() {
        super.init(wave: [0], length: 1, multiplier: 1, hasEnvelope: true)
    }
    
    override func step(_ m: Int) {
        frequencyTimer += m
        while frequencyTimer > frequencyPeriod {
            frequencyTimer -= frequencyPeriod
            shiftLFSR()
            output = enabled ? (lfsr.hasBit(0) ? -1 : 1) * volume : 0
        }
    }
    
    override func trigger() {
        super.trigger()
        lfsr = 0x7FFF
    }
    
    func shiftLFSR() {
        let xorBit = (lfsr ^ lfsr >> 1) & 1
        lfsr = (lfsr >> 1).setBit(14, value: xorBit)
        if shortMode {
            lfsr = lfsr.setBit(6, value: xorBit)
        }
    }
    
    override func writeByte(register: Int, value: Byte) {
        switch register {
        case 1:
            timer = 64 - Int(value & 0x3F)
        case 2: // Volume and envelope values
            super.writeByte(register: register, value: value)
        case 3:
            let divisor = max(4 * (value & 0x3), 2)
            frequencyPeriod = Int(divisor) << (value >> 4)
            shortMode = value.hasBit(3)
        case 4:
            if value.hasBit(7) { trigger() }
            enableTimer = value.hasBit(6)
        default:
            fatalError()
        }
    }
}
