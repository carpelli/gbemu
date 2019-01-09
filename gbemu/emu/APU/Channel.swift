//
//  Channel.swift
//  gbemu
//
//  Created by Otis Carpay on 28/12/2018.
//  Copyright © 2018 Otis Carpay. All rights reserved.
//

import Cocoa

class Modulator<Prop> {
    enum Mode {
        case increase, decrease
    }
    
    let stepFunc: (Prop, Mode) -> Prop
    let countsPerStep: Int
    var mode: Mode
    var prop: Prop
    var period = 0
    var count = 0
    
    init(value: Prop, mode: Mode, countsPerStep: Int, stepFunc: @escaping (Prop, Mode) -> Prop) {
        prop = value
        self.mode = mode
        self.stepFunc = stepFunc
        self.countsPerStep = countsPerStep
    }
    
    func step(_ prop: Prop) -> Prop {
        if period != 0 {
            count += 1
            if count == countsPerStep * period { // todo reverse
                count = 0
                self.prop = stepFunc(prop, mode)
                return self.prop
            }
        }
        return prop
    }
}

class Channel {
    // No envelope for waveChannel
    var initialVolume = 0
    private let envelope: Modulator<Double>?
    
    enum Which: Int {
        case ch1 = 1, ch2, wave
    }
    
    var timer = 0 // Change name(s)
    var enableTimer = false
    
    var frequency = 0 {
        didSet { frequencyPeriod = 2048 - frequency } // In m-cycles
    }
    var frequencyTimer = 0
    var frequencyPeriod = 2
    let multiplier: Int
    
    var volume = 0.0
    var enabled = false
    
    let waveLength: Int
    var wave: [Double]
    var wavePointer = 0
    
    var output = 0.0
    
    init(wave: [Double], length: Int, multiplier: Int, hasEnvelope: Bool) {
        self.multiplier = multiplier
        self.waveLength = length
        self.wave = wave
        if hasEnvelope {
            envelope = Modulator<Double>(
                value: 15,
                mode: .increase,
                countsPerStep: 4,
                stepFunc: { volume, mode in
                    return min(max(volume + (mode == .increase ? 1.0/15 : -1.0/15), 0), 1)
            })
        } else {
            envelope = nil
        }
    }
    
    func step(_ m: Int) {
        frequencyTimer += multiplier * m
        while frequencyTimer > frequencyPeriod {
            frequencyTimer -= frequencyPeriod
            wavePointer = (wavePointer + 1) % waveLength
            output = enabled ? Double(-1 + 2 * wave[wavePointer]) * volume : 0
        }
    }
    
    func stepModulators() {
        if timer != 0 || !enableTimer {
            volume = envelope?.step(volume) ?? volume
            if enableTimer { timer -= 1 }
        } else {
            enabled = false
        }
    }
    
    func trigger() {
        envelope?.count = 0
        if envelope != nil { volume = Double(initialVolume) / 15 }
        enabled = true
        //frequencyTimer = 0
        if timer == 0 {
            timer = multiplier == 1 ? 64 : 256 // fixme
        }
    }
    
    func writeByte(register: Int, value: Byte) {
        switch register {
        // case 1 (& 2 for wave) to be implemented by subclasses
        case 2:
            initialVolume = Int(value >> 4)
            envelope?.mode = value.hasBit(3) ? .increase : .decrease
            envelope?.period = Int(value & 0x7)
        case 3:
            frequency = frequency & 0x700 | Int(value)
        case 4:
            if value.hasBit(7) { trigger() }
            enableTimer = value.hasBit(6)
            frequency = frequency & 0xFF | Int(value & 0x7) << 8
        default: fatalError()
        }
    }
}
