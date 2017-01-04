//
//  Joypad.swift
//  gbemu
//
//  Created by Otis Carpay on 09/09/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Swift

protocol JoypadInput {
    func connectToJoypad(_ joypad: Joypad)
}

class Joypad {
    enum Button {
        case a, b, select, start, right, left, up, down
    }
    
    private let mmu: MMU
    
    private var rows: [Byte] = [0x0F, 0x0F]
    private var column: Byte = 0
    
    init(input: JoypadInput, mmu: MMU) {
        self.mmu = mmu
        input.connectToJoypad(self)
    }
    
    func readByte() -> Byte {
        switch column {
            case 0x10: return rows[0]
            case 0x20: return rows[1]
            default: return 0
        }
    }
    
    func writeByte(_ value: Byte) {
        column = value & 0x30
    }
    
    func buttonDown(_ button: Button) {
        switch button {
            case .a:      rows[0] &= 0b1110
            case .b:      rows[0] &= 0b1101
            case .select: rows[0] &= 0b1011
            case .start:  rows[0] &= 0b0111
            case .right:  rows[1] &= 0b1110
            case .left:   rows[1] &= 0b1101
            case .up:     rows[1] &= 0b1011
            case .down:   rows[1] &= 0b0111
        }
        mmu.iFlag[4] = true
    }
    
    func buttonUp(_ button: Button) {
        switch button {
            case .a:      rows[0] |= 0b0001
            case .b:      rows[0] |= 0b0010
            case .select: rows[0] |= 0b0100
            case .start:  rows[0] |= 0b1000
            case .right:  rows[1] |= 0b0001
            case .left:   rows[1] |= 0b0010
            case .up:     rows[1] |= 0b0100
            case .down:   rows[1] |= 0b1000
        }
    }
}
