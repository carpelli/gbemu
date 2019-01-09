//
//  File.swift
//  gbemu
//
//  Created by Otis Carpay on 29/12/2018.
//  Copyright © 2018 Otis Carpay. All rights reserved.
//

import Foundation
import AudioToolbox

func outputCallback(_ data: UnsafeMutableRawPointer?, queue: AudioQueueRef, buffer: AudioQueueBufferRef) {
    let apu = Unmanaged<APU>.fromOpaque(data!).takeUnretainedValue()
    
    apu.buffer.load(to: buffer, size: 735)
    AudioQueueEnqueueBuffer(queue, buffer, 0, nil)
}

class AudioPlayer {
    var dataFormat: AudioStreamBasicDescription
    var queue: AudioQueueRef?
    var buffers = [AudioQueueBufferRef?](repeating: nil, count: 2)
    var bufferByteSize: UInt32
    var numPacketsToRead: UInt32
    var packetsToPlay: UInt32
    var apu = APU()
    
    init() {
        dataFormat = AudioStreamBasicDescription(
            mSampleRate: 44100,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked, // Bigendian??
            mBytesPerPacket: 2,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        bufferByteSize = 735*2 // TODO better size
        numPacketsToRead = 0
        packetsToPlay = 1
    }
    
    func start(with apu: APU) {
        let apu = apu
        if let queue = queue {
            if let buffer = buffers[0] { AudioQueueFreeBuffer(queue, buffer) } // <- V not necessary
            if let buffer = buffers[1] { AudioQueueFreeBuffer(queue, buffer) }
            AudioQueueDispose(queue, true)
        }
        
        AudioQueueNewOutput(&dataFormat, outputCallback, Unmanaged.passUnretained(apu).toOpaque(), CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue, 0, &queue)
        //Strong referencing or possibly nil???
        guard let queue = queue else {
            print("Failed to init audio queue")
            return
        }
        
        for case var buffer in buffers {
            AudioQueueAllocateBuffer(queue, bufferByteSize, &buffer)
            outputCallback(Unmanaged.passUnretained(apu).toOpaque(), queue: queue, buffer: buffer!)
        }
        
        AudioQueueStart(queue, nil)
    }
}
