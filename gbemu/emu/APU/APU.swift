//
//  Sound.swift
//  gbemu
//
//  Created by Otis Carpay on 03/01/2017.
//  Copyright © 2017 Otis Carpay. All rights reserved.
//

final class APU {
    var internalCount = 0
    var sampleTimer = 0.0
    
    var buffer = Buffer()
    var stepsPerSample = mStepsPerSample
    
    var channel1 = Square(doesSweep: true)
    var channel2 = Square(doesSweep: false)
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
        
        channel1.step(m)
        channel2.step(m)
        waveChannel.step(m)
        noiseChannel.step(m)
        
        if sampleTimer > stepsPerSample {
            sampleTimer -= stepsPerSample
            
            buffer.put(sample: Int16(
                (channel1.output + channel2.output + waveChannel.output + noiseChannel.output) * 0.1 * Double(Int16.max)
            ))
        }
        
        if internalCount > 4096 { // 256 Hz
            internalCount -= 4096
            channel1.stepModulators()
            channel2.stepModulators()
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
            case 0xFF10 ... 0xFF14: channel1.writeByte(register: address - 0xFF10, value: value)
            case 0xFF15 ... 0xFF19: channel2.writeByte(register: address - 0xFF15, value: value)
            case 0xFF1A ... 0xFF1E: waveChannel.writeByte(register: address - 0xFF1A, value: value)
            case 0xFF1F ... 0xFF23: noiseChannel.writeByte(register: address - 0xFF1F, value: value)
            case 0xFF30 ... 0xFF3F: waveChannel.writeWaveTable(register: address - 0xFF30, value: value)
            default: break
        }
    }
    
    deinit {
        print("APU released")
    }
}
