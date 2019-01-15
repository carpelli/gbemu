//
//  Buffer.swift
//  gbemu
//
//  Created by Otis Carpay on 08/01/2019.
//  Copyright © 2019 Otis Carpay. All rights reserved.
//

import AudioToolbox

let mStepsPerSample = 1_048_567/44100.0

struct Buffer {
    static let size = 44100
    static let idealCapacity = 1500.0
    static let alpha = 0.01
    static let alpha2 = 0.01
    
    private var buffer = [Int32](repeating: 0, count: size)
    private var readPointer = 0
    private var writePointer = Int(idealCapacity) + 735*2
    private var rollingSamplesToGet = mStepsPerSample
    
    private var isFirstSample = true
    
    weak var apu: APU?
    
    mutating func put(sample: Int32) {
        buffer[writePointer % Buffer.size] = sample
        writePointer += 1
        if (writePointer - readPointer) % Buffer.size == 0 {
//            print("Buffer overflow")
        }
    }
    
    mutating func load(to bufferRef: AudioQueueBufferRef, size: Int) {
        guard size == bufferRef.pointee.mAudioDataBytesCapacity / 4 else { fatalError() }
        let aqBuffer = UnsafeMutableBufferPointer(
            start: bufferRef.pointee.mAudioData.assumingMemoryBound(to: Int32.self),
            count: size
        )
        for i in 0..<size {
            aqBuffer[i] = buffer[readPointer % Buffer.size]
            readPointer += 1
            
            if (writePointer - readPointer) % Buffer.size == 0 {
//                print("Buffer underflow")
                for j in i+1..<size {
                    aqBuffer[j] = 0
                }
                break
            }
        }
        bufferRef.pointee.mAudioDataByteSize = 735*4
        if isFirstSample {
            isFirstSample = false
        } else {
            apu?.stepsPerSample = calculateSampleClockLength()
        }
    }
    
    mutating func calculateSampleClockLength() -> Double {
        let availableSamples = writePointer - readPointer
        let capacityModifier = Double(availableSamples) / Buffer.idealCapacity
        rollingSamplesToGet =
            Buffer.alpha * mStepsPerSample * capacityModifier +
            (1 - Buffer.alpha) * rollingSamplesToGet
        return rollingSamplesToGet
//        let distanceInSamples = Double(availableSamples) / Buffer.idealCapacity - 1
//        let modifier = 1 - distanceInSamples * distanceInSamples * Buffer.alpha2
//        return modifier * mStepsPerSample
    }
}
