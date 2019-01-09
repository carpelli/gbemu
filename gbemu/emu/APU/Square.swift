//
//  Square.swift
//  gbemu
//
//  Created by Otis Carpay on 29/12/2018.
//  Copyright © 2018 Otis Carpay. All rights reserved.
//

private let dutyTables: [[Double]] = [
    [0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 1, 1, 1],
    [0, 1, 1, 1, 1, 1, 1, 0]
]

class Square: Channel {
    var sweepShift = 0
    let doesSweep: Bool
    lazy private var sweep = Modulator<Int>(
        value: 0, //frequency
        mode: .decrease,
        countsPerStep: 2,
        stepFunc: { [unowned self] frequency, mode in
            return frequency + (mode == .increase ? (frequency >> self.sweepShift) : -(frequency >> self.sweepShift))
    })
    
    init(doesSweep: Bool) {
        self.doesSweep = doesSweep
        super.init(wave: dutyTables[2], length: 8, multiplier: 1, hasEnvelope: true)
    }
    
    override func stepModulators() {
        if timer != 0 || !enableTimer {
            if doesSweep && sweepShift != 0 {
                let newFrequency = sweep.step(frequency)
                if newFrequency > 0x7FF || newFrequency < 0 {
                    timer = 0
                    volume = 0
                } else {
                    frequency = newFrequency
                }
            }
        }
        super.stepModulators()
    }
    
    override func trigger() {
        super.trigger()
        if doesSweep {
            sweep.count = 0
            if sweep.period != 0 && sweepShift != 0 {
                //perform one sweep step immediately
                frequency += (sweep.mode == .increase ? (frequency >> sweepShift) : -(frequency >> sweepShift))
                sweep.prop = frequency
            }
        }
    }
    
    override func writeByte(register: Int, value: Byte) {
        switch register {
        case 0:
            if doesSweep {
                sweep.period = Int(value & 0x70) >> 4
                sweep.mode = value.hasBit(3) ? .decrease : .increase
                sweepShift = Int(value & 0x7)
            }
        case 1:
            wave = dutyTables[Int(value >> 6)]
            timer = 64 - Int(value & 0x3F)
        default:
            super.writeByte(register: register, value: value)
        }
    }
}
