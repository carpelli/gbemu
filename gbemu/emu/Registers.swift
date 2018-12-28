//
//  Registers.swift
//  gbemu
//
//  Created by Otis Carpay on 09/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Swift

class Registers {
    struct Flags {
        var Z = false //Zero
        var N = false //Subtraction
        var H = false //Half-Carry
        var C = false //Carry
        
        ///Flags as the byte they are
        var byte: Byte {
            get {
                return (
                    (Z ? 0b10000000 : 0) |
                    (N ? 0b01000000 : 0) |
                    (H ? 0b00100000 : 0) |
                    (C ? 0b00010000 : 0)
                )
            }
            set {
                Z = newValue & 0b10000000 != 0
                N = newValue & 0b01000000 != 0
                H = newValue & 0b00100000 != 0
                C = newValue & 0b00010000 != 0
            }
        }
    }
    
    //8-bit registers
    var a, b, c, d, e, h, l: Byte
    var flags = Flags()
    //
    var pc, sp: Word
    var m = 0, t = 0
    
    var hl: Word {
        get { return (UInt16(h) << 8) | UInt16(l) }
        set { h = Byte(newValue >> 8); l = Byte(truncatingIfNeeded: newValue)}
    }
    
    var bc: Word {
        get { return (UInt16(b) << 8) | UInt16(c) }
        set { b = Byte(newValue >> 8); c = Byte(truncatingIfNeeded: newValue)}
    }
    
    var de: Word {
        get { return (UInt16(d) << 8) | UInt16(e) }
        set { d = Byte(newValue >> 8); e = Byte(truncatingIfNeeded: newValue)}
    }
    
    var af: Word {
        get { return (UInt16(a) << 8) | UInt16(flags.byte) }
        set { a = Byte(newValue >> 8); flags.byte = Byte(truncatingIfNeeded: newValue)}
    }
    
    init() {
        a = 0x01
        b = 0x00
        c = 0x13
        d = 0x00
        e = 0xD8
        h = 0x01
        l = 0x4D
        flags.byte = 0xB0
        
        pc = 0x100
        sp = 0xFFFE
    }
}
