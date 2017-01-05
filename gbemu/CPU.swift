//
//  z80.swift
//  gbemu
//
//  Created by Otis Carpay on 09/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Foundation

var opsPerformed = 0

final class CPU {
    let mmu: MMU
    let system: Gameboy
    
    var debug = false
    var cycle = 0
    var reg = Registers()
    var enableInterrupts = false
    var halted = false
    
    var oldPCs = [Word](repeating: 0, count: 100)
    var pointer = 0
    func printPCs() {
        var array = Array(oldPCs.suffix(from: pointer))
        array.append(contentsOf: oldPCs.prefix(upTo: pointer))
        for element in array {
            print(String(format: "%04x", element))
        }
    }
    
    var ops = 0
    
    let OPTIMES = [
        1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1,
        1, 3, 2, 2, 1, 1, 2, 1, 3, 2, 2, 2, 1, 1, 2, 1,
        2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1,
        2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
        2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
        1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
        2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 1, 3, 3, 2, 4,
        2, 3, 3, 0, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4,
        3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4,
        3, 3, 2, 1, 0, 4, 2, 4, 3, 2, 4, 1, 0, 0, 2, 4,
    ]
    
    init(system: Gameboy) {
        self.system = system
        mmu = MMU(system: system)
    }
    
    private func fetchByte() -> Byte {
        let value = mmu.readByte(reg.pc)
        reg.pc += 1
        return value
    }
    
    private func fetchWord() -> Word {
        let value = mmu.readWord(reg.pc)
        reg.pc += 2
        return value
    }
    
    func step() -> Int {
        if reg.pc > 0x100 { mmu.isInBios = false }
        
        cycle = 0
        
        handleInterrupt()
        oldPCs[pointer] = reg.pc
        pointer = (pointer + 1) % 100
        
        if reg.pc == 0x79 {
            
        }
        
        if reg.pc == 0x89 {
        
        }
        
        ops += 1
        let oldPC = reg.pc
        
        if !halted {
            call()
            opsPerformed += 1
        } else {
            cycle += 1
        }
        
        mmu.timer.increment(cycle)
        
        if debug { printDebug(oldPC) }
        
        return cycle
    }
    
    func requestInterrupt(_ interrupt: MMU.InterruptByte) {
        mmu.iFlag.insert(interrupt)
    }
    
    private func handleInterrupt() {
        guard enableInterrupts || halted else { return }
        
        let triggered = mmu.iEnable.rawValue & mmu.iFlag.rawValue
        if triggered == 0 { return }
        
        if triggered != 0 {
            if enableInterrupts {
                enableInterrupts = false
                mmu.iFlag = MMU.InterruptByte(rawValue: mmu.iFlag.rawValue & ~triggered)
                
                PUSH(reg.pc) //TODO try to use OptionSet more, performance?
                if triggered & 0b00000001 > 0 { reg.pc = 0x40 } else
                if triggered & 0b00000010 > 0 { reg.pc = 0x48 } else
                if triggered & 0b00000100 > 0 { reg.pc = 0x50 } else
                if triggered & 0b00001000 > 0 { reg.pc = 0x58 } else
                if triggered & 0b00010000 > 0 { reg.pc = 0x60 }
                
                cycle += 3
            }
            halted = false
        }
    }
    
    private func printDebug(_ oldPC: Word) {
        var pcAtOp = oldPC
        let opCode = mmu.readByte(pcAtOp)
        var string: String = String(format: "%4X", ops) + " " +
            String(format: "%4X", pcAtOp) + " "
        string += String(format: "%3X", opCode) + " "
        
        if opCode == 0xCB {
            pcAtOp += 1
            string += OPNAMES_CB[Int(mmu.readByte(pcAtOp))].padding(toLength: 11, withPad: " ", startingAt: 0)
        } else {
            string += OPNAMES[Int(opCode)].padding(toLength: 11, withPad: " ", startingAt: 0)
        }
        
        
//        if reg.pc > pcAtOp {
//            if (reg.pc - pcAtOp) > Word(2) {
//                string += String(format: " %02X", mmu.readByte(pcAtOp + 2))
//            } else {
//                string += "   "
//            }
//            
//            if (reg.pc - pcAtOp) > Word(1) {
//                string += String(format: " %02X", mmu.readByte(pcAtOp + 1))
//            } else {
//                string += "   "
//            }
//        } else {
//            string += "     "
//        }
        string += String(format: " %02X", mmu.readByte(pcAtOp + 2))
        string += String(format: " %02X", mmu.readByte(pcAtOp + 1))
        
        string += "  " + String(format: "%01X %02X %02X %02X %01X  ", reg.a, reg.bc, reg.de, reg.hl, reg.flags.byte)
        
        print(string)
    }
    
    private func call() {
        let opcode = fetchByte()
        
        //Conditional commands will add time if condition is true
        cycle += OPTIMES[Int(opcode)]
        
        switch opcode {
            case 0x00: NOP()
            case 0x01: LD(&reg.bc)
            case 0x02: LD(reg.bc, reg.a)
            case 0x03: INC(&reg.bc)
            case 0x04: INC(&reg.b)
            case 0x05: DEC(&reg.b)
            case 0x06: LD(&reg.b)
            case 0x07: RLCA()
            case 0x08: LD_nn_SP()
            case 0x09: ADD_HL(reg.bc)
            case 0x0A: LD(&reg.a, reg.bc)
            case 0x0B: DEC(&reg.bc)
            case 0x0C: INC(&reg.c)
            case 0x0D: DEC(&reg.c)
            case 0x0E: LD(&reg.c)
            case 0x0F: RRCA()
                
            case 0x10: STOP()
            case 0x11: LD(&reg.de)
            case 0x12: LD(reg.de, reg.a)
            case 0x13: INC(&reg.de)
            case 0x14: INC(&reg.d)
            case 0x15: DEC(&reg.d)
            case 0x16: LD(&reg.d)
            case 0x17: RLA()
            case 0x18: JR()
            case 0x19: ADD_HL(reg.de)
            case 0x1A: LD(&reg.a, reg.de)
            case 0x1B: DEC(&reg.de)
            case 0x1C: INC(&reg.e)
            case 0x1D: DEC(&reg.e)
            case 0x1E: LD(&reg.e)
            case 0x1F: RRA()
                
            case 0x20: JR(!reg.flags.Z)
            case 0x21: LD(&reg.hl)
            case 0x22: LDI_HL_A()
            case 0x23: INC(&reg.hl)
            case 0x24: INC(&reg.h)
            case 0x25: DEC(&reg.h)
            case 0x26: LD(&reg.h)
            case 0x27: DAA()
            case 0x28: JR(reg.flags.Z)
            case 0x29: ADD_HL(reg.hl)
            case 0x2A: LDI_A_HL()
            case 0x2B: DEC(&reg.hl)
            case 0x2C: INC(&reg.l)
            case 0x2D: DEC(&reg.l)
            case 0x2E: LD(&reg.l)
            case 0x2F: CPL()
                
            case 0x30: JR(!reg.flags.C)
            case 0x31: LD(&reg.sp)
            case 0x32: LDD_HL_A()
            case 0x33: INC(&reg.sp)
            case 0x34: INC_HL()
            case 0x35: DEC_HL()
            case 0x36: LD(reg.hl)
            case 0x37: SCF()
            case 0x38: JR(reg.flags.C)
            case 0x39: ADD_HL(reg.sp)
            case 0x3A: LDD_A_HL()
            case 0x3B: DEC(&reg.sp)
            case 0x3C: INC(&reg.a)
            case 0x3D: DEC(&reg.a)
            case 0x3E: LD(&reg.a)
            case 0x3F: CCF()
                
            case 0x40: LD(&reg.b, reg.b)
            case 0x41: LD(&reg.b, reg.c)
            case 0x42: LD(&reg.b, reg.d)
            case 0x43: LD(&reg.b, reg.e)
            case 0x44: LD(&reg.b, reg.h)
            case 0x45: LD(&reg.b, reg.l)
            case 0x46: LD(&reg.b, reg.hl)
            case 0x47: LD(&reg.b, reg.a)
            case 0x48: LD(&reg.c, reg.b)
            case 0x49: LD(&reg.c, reg.c)
            case 0x4A: LD(&reg.c, reg.d)
            case 0x4B: LD(&reg.c, reg.e)
            case 0x4C: LD(&reg.c, reg.h)
            case 0x4D: LD(&reg.c, reg.l)
            case 0x4E: LD(&reg.c, reg.hl)
            case 0x4F: LD(&reg.c, reg.a)
                
            case 0x50: LD(&reg.d, reg.b)
            case 0x51: LD(&reg.d, reg.c)
            case 0x52: LD(&reg.d, reg.d)
            case 0x53: LD(&reg.d, reg.e)
            case 0x54: LD(&reg.d, reg.h)
            case 0x55: LD(&reg.d, reg.l)
            case 0x56: LD(&reg.d, reg.hl)
            case 0x57: LD(&reg.d, reg.a)
            case 0x58: LD(&reg.e, reg.b)
            case 0x59: LD(&reg.e, reg.c)
            case 0x5A: LD(&reg.e, reg.d)
            case 0x5B: LD(&reg.e, reg.e)
            case 0x5C: LD(&reg.e, reg.h)
            case 0x5D: LD(&reg.e, reg.l)
            case 0x5E: LD(&reg.e, reg.hl)
            case 0x5F: LD(&reg.e, reg.a)
                
            case 0x60: LD(&reg.h, reg.b)
            case 0x61: LD(&reg.h, reg.c)
            case 0x62: LD(&reg.h, reg.d)
            case 0x63: LD(&reg.h, reg.e)
            case 0x64: LD(&reg.h, reg.h)
            case 0x65: LD(&reg.h, reg.l)
            case 0x66: LD(&reg.h, reg.hl)
            case 0x67: LD(&reg.h, reg.a)
            case 0x68: LD(&reg.l, reg.b)
            case 0x69: LD(&reg.l, reg.c)
            case 0x6A: LD(&reg.l, reg.d)
            case 0x6B: LD(&reg.l, reg.e)
            case 0x6C: LD(&reg.l, reg.h)
            case 0x6D: LD(&reg.l, reg.l)
            case 0x6E: LD(&reg.l, reg.hl)
            case 0x6F: LD(&reg.l, reg.a)
                
            case 0x70: LD(reg.hl, reg.b)
            case 0x71: LD(reg.hl, reg.c)
            case 0x72: LD(reg.hl, reg.d)
            case 0x73: LD(reg.hl, reg.e)
            case 0x74: LD(reg.hl, reg.h)
            case 0x75: LD(reg.hl, reg.l)
            case 0x76: HALT()
            case 0x77: LD(reg.hl, reg.a)
            case 0x78: LD(&reg.a, reg.b)
            case 0x79: LD(&reg.a, reg.c)
            case 0x7A: LD(&reg.a, reg.d)
            case 0x7B: LD(&reg.a, reg.e)
            case 0x7C: LD(&reg.a, reg.h)
            case 0x7D: LD(&reg.a, reg.l)
            case 0x7E: LD(&reg.a, reg.hl)
            case 0x7F: LD(&reg.a, reg.a)
                
            case 0x80: ADD_A(reg.b)
            case 0x81: ADD_A(reg.c)
            case 0x82: ADD_A(reg.d)
            case 0x83: ADD_A(reg.e)
            case 0x84: ADD_A(reg.h)
            case 0x85: ADD_A(reg.l)
            case 0x86: ADD_A_HL()
            case 0x87: ADD_A(reg.a)
            case 0x88: ADC_A(reg.b)
            case 0x89: ADC_A(reg.c)
            case 0x8A: ADC_A(reg.d)
            case 0x8B: ADC_A(reg.e)
            case 0x8C: ADC_A(reg.h)
            case 0x8D: ADC_A(reg.l)
            case 0x8E: ADC_A_HL()
            case 0x8F: ADC_A(reg.a)
                
            case 0x90: SUB_A(reg.b)
            case 0x91: SUB_A(reg.c)
            case 0x92: SUB_A(reg.d)
            case 0x93: SUB_A(reg.e)
            case 0x94: SUB_A(reg.h)
            case 0x95: SUB_A(reg.l)
            case 0x96: SUB_A_HL()
            case 0x97: SUB_A(reg.a)
            case 0x98: SBC_A(reg.b)
            case 0x99: SBC_A(reg.c)
            case 0x9A: SBC_A(reg.d)
            case 0x9B: SBC_A(reg.e)
            case 0x9C: SBC_A(reg.h)
            case 0x9D: SBC_A(reg.l)
            case 0x9E: SBC_A_HL()
            case 0x9F: SBC_A(reg.a)
                
            case 0xA0: AND_A(reg.b)
            case 0xA1: AND_A(reg.c)
            case 0xA2: AND_A(reg.d)
            case 0xA3: AND_A(reg.e)
            case 0xA4: AND_A(reg.h)
            case 0xA5: AND_A(reg.l)
            case 0xA6: AND_A_HL()
            case 0xA7: AND_A(reg.a)
            case 0xA8: XOR_A(reg.b)
            case 0xA9: XOR_A(reg.c)
            case 0xAA: XOR_A(reg.d)
            case 0xAB: XOR_A(reg.e)
            case 0xAC: XOR_A(reg.h)
            case 0xAD: XOR_A(reg.l)
            case 0xAE: XOR_A_HL()
            case 0xAF: XOR_A(reg.a)
                
            case 0xB0: OR_A(reg.b)
            case 0xB1: OR_A(reg.c)
            case 0xB2: OR_A(reg.d)
            case 0xB3: OR_A(reg.e)
            case 0xB4: OR_A(reg.h)
            case 0xB5: OR_A(reg.l)
            case 0xB6: OR_A_HL()
            case 0xB7: OR_A(reg.a)
            case 0xB8: CP_A(reg.b)
            case 0xB9: CP_A(reg.c)
            case 0xBA: CP_A(reg.d)
            case 0xBB: CP_A(reg.e)
            case 0xBC: CP_A(reg.h)
            case 0xBD: CP_A(reg.l)
            case 0xBE: CP_A_HL()
            case 0xBF: CP_A(reg.a)
                
            case 0xC0: RET(!reg.flags.Z)
            case 0xC1: POP(&reg.bc)
            case 0xC2: JP(!reg.flags.Z)
            case 0xC3: JP()
            case 0xC4: CALL(!reg.flags.Z)
            case 0xC5: PUSH(reg.bc)
            case 0xC6: ADD_A_n()
            case 0xC7: RST(0x00)
            case 0xC8: RET(reg.flags.Z)
            case 0xC9: RET()
            case 0xCA: JP(reg.flags.Z)
            case 0xCB: call_CB()
            case 0xCC: CALL(reg.flags.Z)
            case 0xCD: CALL()
            case 0xCE: ADC_A_n()
            case 0xCF: RST(0x08)
                
            case 0xD0: RET(!reg.flags.C)
            case 0xD1: POP(&reg.de)
            case 0xD2: JP(!reg.flags.C)
            case 0xD3: __()
            case 0xD4: CALL(!reg.flags.C)
            case 0xD5: PUSH(reg.de)
            case 0xD6: SUB_A_n()
            case 0xD7: RST(0x10)
            case 0xD8: RET(reg.flags.C)
            case 0xD9: RETI()
            case 0xDA: JP(reg.flags.C)
            case 0xDB: __()
            case 0xDC: CALL(reg.flags.C)
            case 0xDD: __()
            case 0xDE: SBC_A_n()
            case 0xDF: RST(0x18)
                
            case 0xE0: LDH_n_A()
            case 0xE1: POP(&reg.hl)
            case 0xE2: LD_C_A()
            case 0xE3: __()
            case 0xE4: __()
            case 0xE5: PUSH(reg.hl)
            case 0xE6: AND_A_n()
            case 0xE7: RST(0x20)
            case 0xE8: ADD_SP()
            case 0xE9: JP_HL()
            case 0xEA: LD_nn(reg.a)
            case 0xEB: __()
            case 0xEC: __()
            case 0xED: __()
            case 0xEE: XOR_A_n()
            case 0xEF: RST(0x28)
                
            case 0xF0: LDH_A_n()
            case 0xF1: POP(&reg.af)
            case 0xF2: LD_A_C() //?????? Disagreement ????????
            case 0xF3: DI()
            case 0xF4: __()
            case 0xF5: PUSH(reg.af)
            case 0xF6: OR_A_n()
            case 0xF7: RST(0x30)
            case 0xF8: LD_HL_SP_e()
            case 0xF9: LD_SP_HL()
            case 0xFA: LD_A_nn()
            case 0xFB: EI()
            case 0xFC: __()
            case 0xFD: __()
            case 0xFE: CP_A_n()
            case 0xFF: RST(0x38)
                
            default: fatalError()
        }
    }
    
    private func call_CB() {
        let opcode = fetchByte()
        
        cycle += (opcode | 0b111 == 0b110) ? 2 : 4
        if (opcode >> 4 | 0b111 > 4) { cycle -= 1 } // correct timing for BIT b (HL) stuff
        
        switch opcode {
            case 0x00: RLC(&reg.b)
            case 0x01: RLC(&reg.c)
            case 0x02: RLC(&reg.d)
            case 0x03: RLC(&reg.e)
            case 0x04: RLC(&reg.h)
            case 0x05: RLC(&reg.l)
            case 0x06: RLC(reg.hl)
            case 0x07: RLC(&reg.a)
            case 0x08: RRC(&reg.b)
            case 0x09: RRC(&reg.c)
            case 0x0A: RRC(&reg.d)
            case 0x0B: RRC(&reg.e)
            case 0x0C: RRC(&reg.h)
            case 0x0D: RRC(&reg.l)
            case 0x0E: RRC(reg.hl)
            case 0x0F: RRC(&reg.a)
                
            case 0x10: RL(&reg.b)
            case 0x11: RL(&reg.c)
            case 0x12: RL(&reg.d)
            case 0x13: RL(&reg.e)
            case 0x14: RL(&reg.h)
            case 0x15: RL(&reg.l)
            case 0x16: RL(reg.hl)
            case 0x17: RL(&reg.a)
            case 0x18: RR(&reg.b)
            case 0x19: RR(&reg.c)
            case 0x1A: RR(&reg.d)
            case 0x1B: RR(&reg.e)
            case 0x1C: RR(&reg.h)
            case 0x1D: RR(&reg.l)
            case 0x1E: RR(reg.hl)
            case 0x1F: RR(&reg.a)
                
            case 0x20: SLA(&reg.b)
            case 0x21: SLA(&reg.c)
            case 0x22: SLA(&reg.d)
            case 0x23: SLA(&reg.e)
            case 0x24: SLA(&reg.h)
            case 0x25: SLA(&reg.l)
            case 0x26: SLA(reg.hl)
            case 0x27: SLA(&reg.a)
            case 0x28: SRA(&reg.b)
            case 0x29: SRA(&reg.c)
            case 0x2A: SRA(&reg.d)
            case 0x2B: SRA(&reg.e)
            case 0x2C: SRA(&reg.h)
            case 0x2D: SRA(&reg.l)
            case 0x2E: SRA(reg.hl)
            case 0x2F: SRA(&reg.a)
                
            case 0x30: SWAP(&reg.b)
            case 0x31: SWAP(&reg.c)
            case 0x32: SWAP(&reg.d)
            case 0x33: SWAP(&reg.e)
            case 0x34: SWAP(&reg.h)
            case 0x35: SWAP(&reg.l)
            case 0x36: SWAP(reg.hl)
            case 0x37: SWAP(&reg.a)
            case 0x38: SRL(&reg.b)
            case 0x39: SRL(&reg.c)
            case 0x3A: SRL(&reg.d)
            case 0x3B: SRL(&reg.e)
            case 0x3C: SRL(&reg.h)
            case 0x3D: SRL(&reg.l)
            case 0x3E: SRL(reg.hl)
            case 0x3F: SRL(&reg.a)
                
            case 0x40: BIT(0, reg.b)
            case 0x41: BIT(0, reg.c)
            case 0x42: BIT(0, reg.d)
            case 0x43: BIT(0, reg.e)
            case 0x44: BIT(0, reg.h)
            case 0x45: BIT(0, reg.l)
            case 0x46: BIT(0, reg.hl)
            case 0x47: BIT(0, reg.a)
            case 0x48: BIT(1, reg.b)
            case 0x49: BIT(1, reg.c)
            case 0x4A: BIT(1, reg.d)
            case 0x4B: BIT(1, reg.e)
            case 0x4C: BIT(1, reg.h)
            case 0x4D: BIT(1, reg.l)
            case 0x4E: BIT(1, reg.hl)
            case 0x4F: BIT(1, reg.a)
                
            case 0x50: BIT(2, reg.b)
            case 0x51: BIT(2, reg.c)
            case 0x52: BIT(2, reg.d)
            case 0x53: BIT(2, reg.e)
            case 0x54: BIT(2, reg.h)
            case 0x55: BIT(2, reg.l)
            case 0x56: BIT(2, reg.hl)
            case 0x57: BIT(2, reg.a)
            case 0x58: BIT(3, reg.b)
            case 0x59: BIT(3, reg.c)
            case 0x5A: BIT(3, reg.d)
            case 0x5B: BIT(3, reg.e)
            case 0x5C: BIT(3, reg.h)
            case 0x5D: BIT(3, reg.l)
            case 0x5E: BIT(3, reg.hl)
            case 0x5F: BIT(3, reg.a)
                
            case 0x60: BIT(4, reg.b)
            case 0x61: BIT(4, reg.c)
            case 0x62: BIT(4, reg.d)
            case 0x63: BIT(4, reg.e)
            case 0x64: BIT(4, reg.h)
            case 0x65: BIT(4, reg.l)
            case 0x66: BIT(4, reg.hl)
            case 0x67: BIT(4, reg.a)
            case 0x68: BIT(5, reg.b)
            case 0x69: BIT(5, reg.c)
            case 0x6A: BIT(5, reg.d)
            case 0x6B: BIT(5, reg.e)
            case 0x6C: BIT(5, reg.h)
            case 0x6D: BIT(5, reg.l)
            case 0x6E: BIT(5, reg.hl)
            case 0x6F: BIT(5, reg.a)
                
            case 0x70: BIT(6, reg.b)
            case 0x71: BIT(6, reg.c)
            case 0x72: BIT(6, reg.d)
            case 0x73: BIT(6, reg.e)
            case 0x74: BIT(6, reg.h)
            case 0x75: BIT(6, reg.l)
            case 0x76: BIT(6, reg.hl)
            case 0x77: BIT(6, reg.a)
            case 0x78: BIT(7, reg.b)
            case 0x79: BIT(7, reg.c)
            case 0x7A: BIT(7, reg.d)
            case 0x7B: BIT(7, reg.e)
            case 0x7C: BIT(7, reg.h)
            case 0x7D: BIT(7, reg.l)
            case 0x7E: BIT(7, reg.hl)
            case 0x7F: BIT(7, reg.a)
                
            case 0x80: RES(0, &reg.b)
            case 0x81: RES(0, &reg.c)
            case 0x82: RES(0, &reg.d)
            case 0x83: RES(0, &reg.e)
            case 0x84: RES(0, &reg.h)
            case 0x85: RES(0, &reg.l)
            case 0x86: RES(0, reg.hl)
            case 0x87: RES(0, &reg.a)
            case 0x88: RES(1, &reg.b)
            case 0x89: RES(1, &reg.c)
            case 0x8A: RES(1, &reg.d)
            case 0x8B: RES(1, &reg.e)
            case 0x8C: RES(1, &reg.h)
            case 0x8D: RES(1, &reg.l)
            case 0x8E: RES(1, reg.hl)
            case 0x8F: RES(1, &reg.a)
                
            case 0x90: RES(2, &reg.b)
            case 0x91: RES(2, &reg.c)
            case 0x92: RES(2, &reg.d)
            case 0x93: RES(2, &reg.e)
            case 0x94: RES(2, &reg.h)
            case 0x95: RES(2, &reg.l)
            case 0x96: RES(2, reg.hl)
            case 0x97: RES(2, &reg.a)
            case 0x98: RES(3, &reg.b)
            case 0x99: RES(3, &reg.c)
            case 0x9A: RES(3, &reg.d)
            case 0x9B: RES(3, &reg.e)
            case 0x9C: RES(3, &reg.h)
            case 0x9D: RES(3, &reg.l)
            case 0x9E: RES(3, reg.hl)
            case 0x9F: RES(3, &reg.a)
                
            case 0xA0: RES(4, &reg.b)
            case 0xA1: RES(4, &reg.c)
            case 0xA2: RES(4, &reg.d)
            case 0xA3: RES(4, &reg.e)
            case 0xA4: RES(4, &reg.h)
            case 0xA5: RES(4, &reg.l)
            case 0xA6: RES(4, reg.hl)
            case 0xA7: RES(4, &reg.a)
            case 0xA8: RES(5, &reg.b)
            case 0xA9: RES(5, &reg.c)
            case 0xAA: RES(5, &reg.d)
            case 0xAB: RES(5, &reg.e)
            case 0xAC: RES(5, &reg.h)
            case 0xAD: RES(5, &reg.l)
            case 0xAE: RES(5, reg.hl)
            case 0xAF: RES(5, &reg.a)
                
            case 0xB0: RES(6, &reg.b)
            case 0xB1: RES(6, &reg.c)
            case 0xB2: RES(6, &reg.d)
            case 0xB3: RES(6, &reg.e)
            case 0xB4: RES(6, &reg.h)
            case 0xB5: RES(6, &reg.l)
            case 0xB6: RES(6, reg.hl)
            case 0xB7: RES(6, &reg.a)
            case 0xB8: RES(7, &reg.b)
            case 0xB9: RES(7, &reg.c)
            case 0xBA: RES(7, &reg.d)
            case 0xBB: RES(7, &reg.e)
            case 0xBC: RES(7, &reg.h)
            case 0xBD: RES(7, &reg.l)
            case 0xBE: RES(7, reg.hl)
            case 0xBF: RES(7, &reg.a)
                
            case 0xC0: SET(0, &reg.b)
            case 0xC1: SET(0, &reg.c)
            case 0xC2: SET(0, &reg.d)
            case 0xC3: SET(0, &reg.e)
            case 0xC4: SET(0, &reg.h)
            case 0xC5: SET(0, &reg.l)
            case 0xC6: SET(0, reg.hl)
            case 0xC7: SET(0, &reg.a)
            case 0xC8: SET(1, &reg.b)
            case 0xC9: SET(1, &reg.c)
            case 0xCA: SET(1, &reg.d)
            case 0xCB: SET(1, &reg.e)
            case 0xCC: SET(1, &reg.h)
            case 0xCD: SET(1, &reg.l)
            case 0xCE: SET(1, reg.hl)
            case 0xCF: SET(1, &reg.a)
                
            case 0xD0: SET(2, &reg.b)
            case 0xD1: SET(2, &reg.c)
            case 0xD2: SET(2, &reg.d)
            case 0xD3: SET(2, &reg.e)
            case 0xD4: SET(2, &reg.h)
            case 0xD5: SET(2, &reg.l)
            case 0xD6: SET(2, reg.hl)
            case 0xD7: SET(2, &reg.a)
            case 0xD8: SET(3, &reg.b)
            case 0xD9: SET(3, &reg.c)
            case 0xDA: SET(3, &reg.d)
            case 0xDB: SET(3, &reg.e)
            case 0xDC: SET(3, &reg.h)
            case 0xDD: SET(3, &reg.l)
            case 0xDE: SET(3, reg.hl)
            case 0xDF: SET(3, &reg.a)
                
            case 0xE0: SET(4, &reg.b)
            case 0xE1: SET(4, &reg.c)
            case 0xE2: SET(4, &reg.d)
            case 0xE3: SET(4, &reg.e)
            case 0xE4: SET(4, &reg.h)
            case 0xE5: SET(4, &reg.l)
            case 0xE6: SET(4, reg.hl)
            case 0xE7: SET(4, &reg.a)
            case 0xE8: SET(5, &reg.b)
            case 0xE9: SET(5, &reg.c)
            case 0xEA: SET(5, &reg.d)
            case 0xEB: SET(5, &reg.e)
            case 0xEC: SET(5, &reg.h)
            case 0xED: SET(5, &reg.l)
            case 0xEE: SET(5, reg.hl)
            case 0xEF: SET(5, &reg.a)
                
            case 0xF0: SET(6, &reg.b)
            case 0xF1: SET(6, &reg.c)
            case 0xF2: SET(6, &reg.d)
            case 0xF3: SET(6, &reg.e)
            case 0xF4: SET(6, &reg.h)
            case 0xF5: SET(6, &reg.l)
            case 0xF6: SET(6, reg.hl)
            case 0xF7: SET(6, &reg.a)
            case 0xF8: SET(7, &reg.b)
            case 0xF9: SET(7, &reg.c)
            case 0xFA: SET(7, &reg.d)
            case 0xFB: SET(7, &reg.e)
            case 0xFC: SET(7, &reg.h)
            case 0xFD: SET(7, &reg.l)
            case 0xFE: SET(7, reg.hl)
            case 0xFF: SET(7, &reg.a)
                
            default: fatalError()
        }
    }
    
    private func NOP() {}
    
    private func __() {
        fatalError("Undefined instruction")
    }
    
    private func HALT() {
        halted = true
    }
    
    private func STOP() {
        //halted = true
    }
    
    /*-------------------
        LOAD COMMANDS
    -------------------*/
    
    ///Loads nn into register
    private func LD(_ rr: inout Word) {
        rr = fetchWord()
        
    }
    
    ///Loads n into register
    private func LD(_ r: inout Byte) {
        r = fetchByte()
    }
    
    ///Loads n into (register)
    private func LD(_ rr: UInt16) {
        mmu.writeByte(rr, value: fetchByte())
    }
    
    ///Loads byte into (register)
    private func LD(_ dd: UInt16, _ r: Byte) {
        mmu.writeByte(dd, value: r)
    }
    
    ///Loads (register) into register
    private func LD(_ r: inout Byte, _ dd: UInt16) {
        r = mmu.readByte(dd)
    }
    
    ///Loads register into register
    private func LD(_ r1: inout Byte, _ r2: Byte) {
        r1 = r2
    }
    
    ///Loads register into (nn)
    private func LD_nn(_ r: Byte) {
        mmu.writeByte(fetchWord(), value: r)
    }
    
    ///Loads sp into (nn)
    private func LD_nn_SP() {
        mmu.writeWord(fetchWord(), value: reg.sp)
    }
    
    ///Loads (nn) into register
    private func LD_A_nn() {
        reg.a = mmu.readByte(fetchWord())
    }
    
    ///Loads ($FF00 + c) into a
    private func LD_A_C() {
        LD(&reg.a, 0xFF00 | Word(reg.c))
    }
    
    ///Loads a into ($FF00 + c)
    private func LD_C_A() {
        LD(0xFF00 | Word(reg.c), reg.a)
    }
    
    ///Loads a into (hl), increases hl
    private func LDI_HL_A() {
        LD(reg.hl, reg.a)
        reg.hl += 1
    }
    
    ///Loads a into (hl), decreases hl
    private func LDD_HL_A() {
        LD(reg.hl, reg.a)
        reg.hl -= 1
    }
    
    ///Loads (hl) into a, increases hl
    private func LDI_A_HL() {
        LD(&reg.a, reg.hl)
        reg.hl += 1
    }
    
    ///Loads (hl) into a, decreases hl
    private func LDD_A_HL() {
        LD(&reg.a, reg.hl)
        reg.hl -= 1
    }
    
    private func LDH_n_A() {
        LD(0xFF00 | Word(fetchByte()), reg.a)
    }
    
    private func LDH_A_n() {
        LD(&reg.a, 0xFF00 | Word(fetchByte()))
    }
    
    private func LD_SP_HL() {
        reg.sp = reg.hl
    }
    
    private func LD_HL_SP_e() {
        let e = Word(bitPattern: Int16(Int8(bitPattern: fetchByte())))
        let sp = reg.sp
        
        reg.hl = sp &+ e
        
        reg.flags.Z = false
        reg.flags.N = false
        reg.flags.H = sp & 0x0F + e & 0x0F > 0x0F
        reg.flags.C = sp & 0xFF + e & 0xFF > 0xFF
    }
    
    private func PUSH(_ rr: Word) {
        reg.sp = reg.sp &- 2
        mmu.writeWord(reg.sp, value: rr)
    }
    
    private func POP(_ rr: inout Word) {
        rr = mmu.readWord(reg.sp)
        reg.sp = reg.sp &+ 2
    }
    
    /*------------------
        ALU COMMANDS
    ------------------*/
    
    ///Adds value to a
    private func ADD_A(_ b: Byte) {
        let a = reg.a
        let r = a &+ b
        
        reg.flags.Z = r == 0
        reg.flags.N = false
        reg.flags.H = (a & 0xF) + (b & 0xF) > 0xF
        reg.flags.C = r < a
        reg.a = r
    }
    
    ///Adds value and C to a
    private func ADC_A(_ b: Byte) {
        let a = reg.a
        let c = Byte(reg.flags.C)
        let r = a &+ b &+ c
        
        reg.flags.Z = r == 0
        reg.flags.N = false
        reg.flags.H = (a & 0xF) + (b & 0xF) + c > 0xF
        reg.flags.C = UInt(a) + UInt(b) + UInt(c) > 0xFF
        reg.a = r
    }
    
    ///Subtracts value from a
    private func SUB_A(_ b: Byte) {
        let a = reg.a
        let r = a &- b
        
        reg.flags.Z = r == 0
        reg.flags.N = true
        reg.flags.H = (a & 0xF) < (b & 0xF)
        reg.flags.C = a < b
        reg.a = r
    }
    
    ///Subtracts value and C from a
    private func SBC_A(_ b: Byte) {
        let a = reg.a
        let c = Byte(reg.flags.C)
        let r = a &- b &- c
    
        reg.flags.Z = r == 0
        reg.flags.N = true
        reg.flags.H = (a & 0xF) < (b & 0xF) + c
        reg.flags.C = UInt(a) < UInt(b) + UInt(c)
        reg.a = r
    }
    
    ///a = a & value
    private func AND_A(_ b: Byte) {
        let r = reg.a & b
        
        reg.flags.Z = r == 0
        reg.flags.N = false
        reg.flags.H = true
        reg.flags.C = false
        reg.a = r
    }
    
    ///a = a | value
    private func OR_A(_ b: Byte) {
        let r = reg.a | b
        
        reg.flags.Z = r == 0
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = false
        reg.a = r
    }
    
    ///a = a ^ value
    private func XOR_A(_ b: Byte) {
        let r = reg.a ^ b
        
        reg.flags.Z = r == 0
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = false
        reg.a = r
    }
    
    ///Update flags as if subtracted value from a
    private func CP_A(_ b: Byte) {
        let a = reg.a
        SUB_A(b)
        
        reg.a = a
    }
    
    ///Increase register by 1
    private func INC(_ b: inout Byte) {
        let r = b &+ 1
        
        reg.flags.Z = r == 0
        reg.flags.N = false
        reg.flags.H = (r & 0xF) == 0
        b = r
    }
    
    ///Increase register by 1
    private func INC(_ ss: inout Word) {
        ss = ss &+ 1
    }
    
    ///Decrease register by 1
    private func DEC(_ b: inout Byte) {
        let r = b &- 1
        
        reg.flags.Z = r == 0
        reg.flags.N = true
        reg.flags.H = (r & 0xF) == 0xF
        b = r
    }
    
    ///Decrease register by 1
    private func DEC(_ ss: inout Word) {
        ss = ss &- 1
    }
    
    private func ADD_A_HL() {
        ADD_A(mmu.readByte(reg.hl))
    }
    
    private func ADC_A_HL() {
        ADC_A(mmu.readByte(reg.hl))
    }
    
    private func SUB_A_HL() {
        SUB_A(mmu.readByte(reg.hl))
    }
    
    private func SBC_A_HL() {
        SBC_A(mmu.readByte(reg.hl))
    }
    
    private func AND_A_HL() {
        AND_A(mmu.readByte(reg.hl))
    }
    
    private func OR_A_HL() {
        OR_A(mmu.readByte(reg.hl))
    }
    
    private func XOR_A_HL() {
        XOR_A(mmu.readByte(reg.hl))
    }
    
    private func CP_A_HL() {
        CP_A(mmu.readByte(reg.hl))
    }
    
    ///Increase (hl) by 1
    private func INC_HL() {
        let r = mmu.readByte(reg.hl) &+ 1
        
        reg.flags.Z = r == 0
        reg.flags.N = false
        reg.flags.H = (r & 0xF) == 0
        mmu.writeByte(reg.hl, value: r)
        
    }
    
    ///Decrease (hl) by 1
    private func DEC_HL() {
        let r = mmu.readByte(reg.hl) &- 1
        
        reg.flags.Z = r == 0
        reg.flags.N = true
        reg.flags.H = (r & 0xF) == 0xF
        mmu.writeByte(reg.hl, value: r)
    }
    
    private func ADD_A_n() {
        ADD_A(fetchByte())
    }
    
    private func ADC_A_n() {
        ADC_A(fetchByte())
    }
    
    private func SUB_A_n() {
        SUB_A(fetchByte())
    }
    
    private func SBC_A_n() {
        SBC_A(fetchByte())
    }
    
    private func AND_A_n() {
        AND_A(fetchByte())
    }
    
    private func OR_A_n() {
        OR_A(fetchByte())
    }
    
    private func XOR_A_n() {
        XOR_A(fetchByte())
    }
    
    private func CP_A_n() {
        CP_A(fetchByte())
    }
    
    ///Add value to hl
    private func ADD_HL(_ ss: Word) {
        let hl = reg.hl
        let r = hl &+ ss
        
        reg.flags.N = false
        reg.flags.H = (hl & 0x0FFF) + (ss & 0x0FFF) > 0x0FFF //?????
        reg.flags.C = hl > 0xFFFF - ss
        reg.hl = r
    }
    
    ///Add signed n (two's complement) to sp
    private func ADD_SP() {
        let e = Word(bitPattern: Int16(Int8(bitPattern: fetchByte())))
        let sp = reg.sp
        
        reg.sp = sp &+ e
        reg.flags.Z = false
        reg.flags.N = false
        reg.flags.H = (sp & 0x000F) + (e & 0x000F) > 0x000F
        reg.flags.C = (sp & 0x00FF) + (e & 0x00FF) > 0x00FF
    }
    
    /*---------------------
        ROTATE COMMANDS
    ---------------------*/
    
    ///Rotate left
    private func RLC(_ s: inout Byte) {
        let c = (s & 0x80) == 0x80
        s = (s << 1) | (c ? 1 : 0)
        
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = c
    }
    
    private func RLC(_ rr: Word) {
        var s = mmu.readByte(rr)
        RLC(&s)
        mmu.writeByte(rr, value: s)
    }
    
    ///Rotate left through carry
    private func RL(_ s: inout Byte) {
        let c = (s & 0x80) == 0x80
        s = (s << 1) | (reg.flags.C ? 1 : 0)
        
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = c
    }
    
    private func RL(_ rr: Word) {
        var s = mmu.readByte(rr)
        RL(&s)
        mmu.writeByte(rr, value: s)
    }
    
    ///Rotate right
    private func RRC(_ s: inout Byte) {
        let c = (s & 0x01) == 0x01
        s = (s >> 1) | (c ? 0x80 : 0)
        
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = c
    }
    
    private func RRC(_ rr: Word) {
        var s = mmu.readByte(rr)
        RRC(&s)
        mmu.writeByte(rr, value: s)
    }
    
    ///Rotate right through carry
    private func RR(_ s: inout Byte) {
        let c = (s & 0x01) == 0x01
        s = (s >> 1) | (reg.flags.C ? 0x80 : 0)
        
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = c
    }
    
    private func RR(_ rr: Word) {
        var s = mmu.readByte(rr)
        RR(&s)
        mmu.writeByte(rr, value: s)
    }
    
    private func RLCA() {
        RLC(&reg.a)
        reg.flags.Z = false
    }
    
    private func RLA() {
        RL(&reg.a)
        reg.flags.Z = false
    }
    
    private func RRCA() {
        RRC(&reg.a)
        reg.flags.Z = false
    }
    
    private func RRA() {
        RR(&reg.a)
        reg.flags.Z = false
    }
    
    /*--------------------
        SHIFT COMMANDS
    --------------------*/
    
    ///Shift left through carry
    private func SLA(_ s: inout Byte) {
        reg.flags.C = s & 0x80 == 0x80
        s = s << 1
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
    }
    
    ///Shift left into carry
    private func SLA(_ rr: Word) {
        var s = mmu.readByte(rr)
        SLA(&s)
        mmu.writeByte(rr, value: s)
    }
    
    ///Logical shift right into carry (pad zero)
    private func SRA(_ s: inout Byte) {
        reg.flags.C = s & 1 == 1
        s = (s >> 1) | (s & 0x80)
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
    }
    
    ///Logical shift right into carry (pad zero)
    private func SRA(_ rr: Word) {
        var s = mmu.readByte(rr)
        SRA(&s)
        mmu.writeByte(rr, value: s)
    }
    
    ///Arithmetic shift right into carry (pad significant)
    private func SRL(_ s: inout Byte) {
        reg.flags.C = s & 1 == 1
        s = s >> 1
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
    }
    
    ///Arithmetic shift right into carry (pad significant)
    private func SRL(_ rr: Word) {
        var s = mmu.readByte(rr)
        SRL(&s)
        mmu.writeByte(rr, value: s)
    }
    
    /*------------------
        BIT COMMANDS
    ------------------*/
    
    ///Set Z to NOT register at bit
    private func BIT(_ bit: Byte, _ s: Byte) {
        assert(bit < 8)
        
        reg.flags.Z = s & (1 << bit) == 0
        reg.flags.N = false
        reg.flags.H = true
    }
    
    ///Set Z to NOT (register) at bit
    private func BIT(_ bit: Byte, _ rr: Word) {
        let s = mmu.readByte(rr)
        BIT(bit, s)
        mmu.writeByte(rr, value: s)
    }
    
    ///Set register at bit
    private func SET(_ bit: Byte, _ s: inout Byte) {
        assert(bit < 8)
        s = s | (1 << bit)
    }
    
    ///Set (register) at bit
    private func SET(_ bit: Byte, _ rr: Word) {
        var s = mmu.readByte(rr)
        SET(bit, &s)
        mmu.writeByte(rr, value: s)
    }
    
    ///Reset register at bit
    private func RES(_ bit: Byte, _ s: inout Byte) {
        assert(bit < 8)
        s = s & ~(1 << bit)
    }
    
    ///Reset (register) at bit
    private func RES(_ bit: Byte, _ rr: Word) {
        var s = mmu.readByte(rr)
        RES(bit, &s)
        mmu.writeByte(rr, value: s)
    }
    
    /*-------------------
        JUMP COMMANDS
    -------------------*/
    
    ///Jump to nn
    private func JP() {
        reg.pc = fetchWord()
    }
    
    ///Jump to hl
    private func JP_HL() {
        reg.pc = reg.hl
    }
    
    ///Jump to nn if flag is set
    private func JP(_ c: Bool) {
        if (c) {
            JP()
            cycle += 1
        } else {
            reg.pc += 2
        }
    }
    
    ///Jump by signed n (two's complement)
    private func JR() {
        let e = Int8(bitPattern: fetchByte())
        reg.pc = Word(truncatingBitPattern: Int32(reg.pc) + Int32(e))
    }
    
    ///Jump by signed n if flag is set
    private func JR(_ c: Bool) {
        if (c) {
            JR()
            cycle += 1
        } else {
            reg.pc += 1
        }
    }
    
    ///Call to nn
    private func CALL() {
        PUSH(reg.pc + 2)
        reg.pc = fetchWord()
    }
    
    ///Call to nn if flag is set
    private func CALL(_ c: Bool) {
        if (c) {
            CALL()
            cycle += 3
        } else {
            reg.pc += 2
        }
    }
    
    ///Return
    private func RET() {
        POP(&reg.pc)
    }
    
    ///Return if flag is set
    private func RET(_ c: Bool) {
        if (c) {
            RET()
            cycle += 3
        }
    }
    
    ///Return and enable interrupts
    private func RETI() {
        EI()
        RET()
    }
    
    ///Call to set value
    private func RST(_ val: Word) {
        PUSH(reg.pc)
        reg.pc = val
    }
    
    /*-------------------
        MISC COMMANDS
    -------------------*/
    
    private func SWAP(_ s: inout Byte) {
        s = (s << 4) | (s >> 4)
        reg.flags.Z = s == 0
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = false
    }
    
    private func SWAP(_ rr: Word) {
        var s = mmu.readByte(rr)
        SWAP(&s)
        mmu.writeByte(rr, value: s)
    }
    
    private func DAA() {
//        var adjust: Byte = reg.flags.C ? 0x60 : 0x00
//        if reg.flags.H {
//            adjust |= 0x06
//        }
//        if !reg.flags.N {
//            if reg.a & 0x0F > 0x09 { adjust |= 0x06 }
//            if reg.a > 0x99 { adjust |= 0x60 }
//            reg.a = reg.a &+ adjust
//        } else {
//            reg.a = reg.a &- adjust
//        }
//        
//        reg.flags.Z = reg.a == 0
//        reg.flags.H = false
//        reg.flags.C = adjust > 0x60
        var a = Int(reg.a)
        
        if (!reg.flags.N) {
            if reg.flags.H || a & 0xF > 0x9 {
                a = a &+ 0x06
            }
            if reg.flags.C || a > 0x9F {
                a = a &+ 0x60
            }
        } else {
            if reg.flags.H {
                a = (a &- 6) & 0xFF
            }
            if reg.flags.C {
                a = a &- 0x60
            }
        }
        
        reg.flags.Z = false
        reg.flags.H = false
        
        if a & 0x100 == 0x100 { reg.flags.C = true }
        
        a &= 0xFF
        reg.a = Byte(truncatingBitPattern: a)
        
        if a == 0 { reg.flags.Z = true }
    }
    
    private func CPL() {
        reg.a = ~reg.a
        reg.flags.N = true
        reg.flags.H = true
    }
    
    private func CCF() {
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = !reg.flags.C
    }
    
    
    private func SCF() {
        reg.flags.N = false
        reg.flags.H = false
        reg.flags.C = true
    }
    
    private func EI() {
        enableInterrupts = true
    }
    
    private func DI() {
        enableInterrupts = false
    }
    
    deinit {
        print("CPU released")
    }
}
