//
//  Sound.swift
//  gbemu
//
//  Created by Otis Carpay on 03/01/2017.
//  Copyright © 2017 Otis Carpay. All rights reserved.
//

private struct Mixer {
    // todo Vin?
    // First four are left channel, last four right
    var enables = (false, false, false, false, false, false, false, false)
    var volume = (left: 0.0, right: 0.0)
    
    func mix(_ ch1: Square, _ ch2: Square, _ ch3: Wave, _ ch4: Noise)
        -> (left: Double, right: Double) {
        return (
            ((enables.0 ? ch1.output : 0) + (enables.1 ? ch2.output : 0) +
            (enables.2 ? ch3.output : 0) + (enables.3 ? ch4.output : 0)) * volume.left * 0.1,
            ((enables.4 ? ch1.output : 0) + (enables.5 ? ch2.output : 0) +
            (enables.6 ? ch3.output : 0) + (enables.7 ? ch4.output : 0)) * volume.right * 0.1
        )
    }
}

final class APU {
    private var internalCount = 0
    private var sampleTimer = 0.0
    private var mixer = Mixer()
    
    var buffer = Buffer()
    var stepsPerSample = mStepsPerSample
    
    var squareChannel1 = Square(doesSweep: true)
    var squareChannel2 = Square(doesSweep: false)
    var waveChannel = Wave()
    var noiseChannel = Noise()
    
    var ioMap = [Byte](repeating: 0xFF, count: 0x100)
    var ioMapMasks: [Byte] = [
        0x80, 0x3F, 0x00, 0xFF, 0xBF,
        0xFF, 0x3F, 0x00, 0xFF, 0xBF,
        0x7F, 0xFF, 0x9F, 0xFF, 0xBF,
        0xFF, 0xFF, 0x00, 0x00, 0xBF,
        0x00, 0x00, 0x70
    ]
    
    init() {
        buffer.apu = self
        ioMapMasks.append(contentsOf: ioMap.dropFirst(ioMapMasks.count)) //FIXME
    }
    
    func toggleChannel(_ channel: Channel.Which) {
        print("Not implemented")
    }
    
    func step(_ m: Int) {
        internalCount += m
        sampleTimer += Double(m)
        
        squareChannel1.step(m)
        squareChannel2.step(m)
        waveChannel.step(m)
        noiseChannel.step(m)
        
        if sampleTimer > stepsPerSample {
            sampleTimer -= stepsPerSample
            
            let signal = mixer.mix(squareChannel1, squareChannel2, waveChannel, noiseChannel)
            buffer.put(sample:
                Int32(signal.right * Double(Int16.max)) << 16 +
                Int32(signal.left * Double(Int16.max))
            )
        }
        
        if internalCount > 4096 { // 256 Hz
            internalCount -= 4096
            squareChannel1.stepModulators()
            squareChannel2.stepModulators()
            waveChannel.stepModulators()
            noiseChannel.stepModulators()
        }
    }
    
    func readByte(_ address: Int) -> Byte {
        let returnValue = ioMap[address & 0xFF]
        
        return returnValue //FIXME
    }
    
    func writeByte(_ address: Int, value: Byte) {
        ioMap[address & 0xFF] = value | ioMapMasks[address & 0xFF]
        switch (address) {
            case 0xFF10 ... 0xFF14: squareChannel1.writeByte(register: address - 0xFF10, value: value)
            case 0xFF15 ... 0xFF19: squareChannel2.writeByte(register: address - 0xFF15, value: value)
            case 0xFF1A ... 0xFF1E: waveChannel.writeByte(register: address - 0xFF1A, value: value)
            case 0xFF1F ... 0xFF23: noiseChannel.writeByte(register: address - 0xFF1F, value: value)
            case 0xFF24: mixer.volume = (Double(value >> 4 & 0x7) / 7, Double(value & 0x7) / 7)
            case 0xFF25: mixer.enables = value.inBools()
            case 0xFF30 ... 0xFF3F: waveChannel.writeWaveTable(register: address - 0xFF30, value: value)
            default: break
        }
    }
    
    deinit {
        print("APU released")
    }
}
