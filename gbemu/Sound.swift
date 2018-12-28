//
//  Sound.swift
//  gbemu
//
//  Created by Otis Carpay on 03/01/2017.
//  Copyright © 2017 Otis Carpay. All rights reserved.
//

import AudioKit

final class Sound {
    var internalCount = 0
    
    var channel1 = Channel(withSweep: true)
    var channel2 = Channel(withSweep: false)
    var waveChannel = Wave()
    var togglePanel: TogglePanel
    
    var ioMap = [Byte](repeating: 0xFF, count: 0x100)
    var ioMapMasks: [Byte] = [
        0x80, 0x3F, 0x00, 0xFF, 0xBF,
        0xFF, 0x3F, 0x00, 0xFF, 0xBF,
        0x7F, 0xFF, 0x9F, 0xFF, 0xBF,
        0xFF, 0xFF, 0x00, 0x00, 0xBF,
        0x00, 0x00, 0x70
    ]
    
    enum ChannelType: Int {
        case ch1 = 1, ch2, wave
    }
    
    class TogglePanel {
        let mixers = [AKMixer(), AKMixer(), AKMixer()]
        let ch1, ch2: Channel
        let wave: Wave
        
        init(ch1: Channel, ch2: Channel, wave: Wave, output: AKMixer) {
            self.ch1 = ch1
            self.ch2 = ch2
            self.wave = wave
            
            ch1.oscillator.connect(to: mixers[0])
            ch2.oscillator.connect(to: mixers[1])
            wave.mixer.connect(to: mixers[2])
            
            let finalMixer = AKMixer()
            for mixer in mixers {
                mixer.connect(to: finalMixer)
            }
            finalMixer.connect(to: output)
        }
        
        func toggle(channel: ChannelType) {
            let mixer = mixers[channel.rawValue - 1]
            mixer.volume = 1 - mixer.volume
            print(mixers.map { $0.volume })
        }
    }
    
    class Channel {
        struct Envelope {
            enum Mode { case increase, decrease }
            var initialVolume = 0
            var mode = Mode.decrease
            var period = 0
            
            var count = 0
            
            mutating func step(amplitude: Double) -> Double {
                if period != 0 {
                    count += 1
                    if count == 4 * period {
                        count = 0
                        return amplitude + (mode == .increase ? 1.0/16 : -1.0/16)
                    }
                }
                return amplitude
            }
        }
        
        struct Sweep {
            enum Mode { case increase, decrease }
            var enabled = false
            var period = 0
            var mode = Mode.increase
            var shift = 0
            var frequency = 0 //frequency shadow register
            
            var count = 0
            
            mutating func step(frequency: Int) -> Int {
                if period != 0 && shift != 0 {
                    count += 1
                    if count == 2 * period {
                        count = 0
                        self.frequency += (mode == .increase ? (frequency >> shift) : -(frequency >> shift))
                        return self.frequency
                    }
                }
                return frequency
            }
            
            mutating func trigger(frequency: Int) -> Int {
                self.frequency = frequency
                count = 0
                if period != 0 && shift != 0 {
                    self.frequency += (mode == .increase ? (frequency >> shift) : -(frequency >> shift))
                    return self.frequency
                }
                return frequency
            }
        }
        
        static let squareWaves = [
            [0, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 0, 0, 1],
            [1, 0, 0, 0, 0, 1, 1, 1],
            [0, 1, 1, 1, 1, 1, 1, 0],
        ].map() { array -> AKTable in
            var wave = AKTable(.square, count: 8)
            for i in 0..<8 {
                wave[i] = Float(array[i])
            }
            return wave
        }
        
        var sweep = Sweep()
        
        var wave = squareWaves[0]
        var envelope = Envelope()
        var envelopeCount = 0
        var timer = 0
        
        var frequency = 0 {
            didSet { oscillator.frequency = 131072/(2048-Double(frequency)) }
        }
        var intial = false
        var enableTimer = false
        
        var oscillator = AKOscillator(waveform: AKTable(.square))
        
        init(withSweep: Bool) {
            sweep.enabled = withSweep
            oscillator.amplitude = 0
            oscillator.frequency = 131072/2048
            oscillator.rampDuration = 0
        }
        
        func step() {
            if timer != 0 || !enableTimer {
                if enableTimer { timer -= 1 }
                oscillator.amplitude = envelope.step(amplitude: oscillator.amplitude)
                if sweep.enabled {
                    let newFrequency = sweep.step(frequency: frequency)
                    if newFrequency > 0x7FF || newFrequency < 0 {
                        timer = 0
                        oscillator.amplitude = 0
                    } else {
                        frequency = newFrequency
                    }
                }
            } else {
                oscillator.amplitude = 0
            }
        }
        
        func trigger() {
            if timer == 0 {
                timer = 64
            }
            envelope.count = 0
            oscillator.amplitude = envelope.initialVolume / 16
            if sweep.enabled { frequency = sweep.trigger(frequency: frequency) }
        }
        
        func write(register: Int, value: Byte) {
            switch register {
                case 0:
                    if sweep.enabled {
                        sweep.period = Int(value & 0x70) >> 4
                        sweep.mode = value.hasBit(3) ? .decrease : .increase
                        sweep.shift = Int(value & 0x7)
                    }
                case 1:
                    wave = Channel.squareWaves[Int(value >> 6)] //FIXME
                    timer = Int(value & 0x3F)
                case 2:
                    envelope.initialVolume = Int(value >> 4)
                    envelope.mode = value.hasBit(3) ? .increase : .decrease
                    envelope.period = Int(value & 0x7)
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
    
    class Wave {
        var waveTable = AKTable(.sine, count: 32)
        var dacPower = 0
        var timer = 0
        var enableTimer = false
        var frequency = 0 {
            didSet { oscillator?.frequency = 131072/(2048-Double(frequency))/2 }
        }
        var volume = 0.0 {
            didSet { if enabled { mixer.volume = volume } }
        }
        var enabled = false
        
        var waveTables: [[Byte]] = []
        var currentWaveTable = [Byte](repeating: 0, count: 16)
        var oscillators: [AKOscillator] = []
        var oscillator: AKOscillator?
        
        var mixer = AKMixer()
        
        func step() {
            if timer != 0 || !enableTimer {
                if enableTimer { timer -= 1 }
            } else {
                enabled = false
                mixer.volume = 0
            }
        }
        
        func trigger() {
            if timer == 0 {
                timer = 256
            }
            enabled = true
            mixer.volume = volume
            addWaveTable()
            if volume != 0 {
                
            }
        }
        
        func write(register: Int, value: Byte) {
            switch register {
                case 0: break
                case 1:
                    timer = Int(value)
                case 2:
                    switch value >> 5 & 3 {
                        case 0: volume = 0
                        case 1: volume = 1
                        case 2: volume = 0.5
                        case 3: volume = 0.25
                        default: break
                    }
                case 3:
                    frequency = frequency & 0x700 | Int(value)
                case 4:
                    if value.hasBit(7) { trigger() }
                    enableTimer = value.hasBit(6)
                    frequency = frequency & 0xFF | Int(value & 0x7) << 8
                default: fatalError()
            }
        }
        
        func writeWaveTable(register: Int, value: Byte) {
            currentWaveTable[register] = value
        }
        
        func addWaveTable() {
            for (index, table) in waveTables.enumerated() {
                if currentWaveTable == table {
                    changeOscillator(oscillators[index])
                    return
                }
            }
            waveTables.append(currentWaveTable)
            let akTable = AKTable(count: 32)
            for i in 0..<16 {
                akTable[i * 2] = Float(currentWaveTable[i] >> 4) / Float(15)
                akTable[i * 2 + 1] = Float(currentWaveTable[i] & 0xF) / Float(15)
            }
            let newOscillator = AKOscillator(waveform: akTable)
            newOscillator.rampDuration = 0
            oscillators.append(newOscillator)
            newOscillator.connect(to: mixer)
            changeOscillator(newOscillator)
            print("Added wave oscillator #\(waveTables.count)")
        }
        
        func changeOscillator(_ newOscillator: AKOscillator) {
            let frequency = oscillator?.frequency
            oscillator?.stop()
            oscillator = newOscillator
            oscillator!.frequency = frequency ?? 0
            oscillator!.start()
        }
    }
    
    init() {
        togglePanel = TogglePanel(
            ch1: channel1,
            ch2: channel2,
            wave: waveChannel,
            output: AudioKit.output as! AKMixer
        )
        channel1.oscillator.start()
        channel2.oscillator.start()
        
        ioMapMasks.append(contentsOf: ioMap.dropFirst(ioMapMasks.count)) //FIXME
    }
    
    func toggleChannel(_ channel: ChannelType) {
        togglePanel.toggle(channel: channel)
    }
    
    func step(_ m: Int) {
        internalCount += m
        if internalCount > 4096 { // 256 Hz
            internalCount -= 4096
            channel1.step()
            channel2.step()
        }
    }
    
    func readByte(_ address: Int) -> Byte {
        let returnValue = ioMap[address & 0xFF]
        
        return returnValue //FIXME
    }
    
    var waveTables: [[Byte]] = []
    var newTable = [Byte](repeating: 0, count: 16)
    
    func writeByte(_ address: Int, value: Byte) {
        ioMap[address & 0xFF] = value | ioMapMasks[address & 0xFF]
        switch (address) {
            case 0xFF10 ... 0xFF14: channel1.write(register: address - 0xFF10, value: value)
            case 0xFF15 ... 0xFF19: channel2.write(register: address - 0xFF15, value: value)
            case 0xFF1A ... 0xFF1E: waveChannel.write(register: address - 0xFF1A, value: value)
            case 0xFF30 ... 0xFF3F: waveChannel.writeWaveTable(register: address - 0xFF30, value: value)
            default: break
        }
    }
    
    deinit {
        channel1.oscillator.stop()
        channel2.oscillator.stop()
        waveChannel.oscillator?.stop()
        waveChannel.mixer.stop()
        print("APU released")
    }
}
