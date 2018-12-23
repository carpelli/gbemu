//
//  MBCProtocol.swift
//  gbemu
//
//  Created by Otis Carpay on 04/01/2017.
//  Copyright © 2017 Otis Carpay. All rights reserved.
//

final class Cartridge {
    enum MBC: Byte {
        case noMBC = 0, mbc1, mbcExternalRAM, mbcBattery
    }
    
    enum ExpansionMode {
        case rom, ram
    }
    
    let rom: [Byte]
    var ram = [Byte](repeating: 0, count: 0x8000)
    let mbc: MBC
    var mode = ExpansionMode.rom
    
    let name: String
    
    var romOffset = 0x4000
    var ramOffset = 0x0000
    var romBank = 0
    var romSize = 0
    var ramBank = 0
    var ramOn = false
    let ramSize: Int
    
    init(data: [Byte]) {
        rom = data
        
        if let type = MBC(rawValue: rom[0x0147]) {
            mbc = type
            ramSize = Int(rom[0x0149])
            
            let romSizeValue = rom[0x0148]
            switch romSizeValue {
                case 0...7:
                    romSize = 2 << Int(romSizeValue)
                default: fatalError()
            }
            
            var name = ""
            for char in rom[0x0134...0x0143] {
                if char == 0 { break }
                name.append(Character(UnicodeScalar(char)))
            }
            self.name = name
            
            loadRAM()
        } else {
            fatalError("MBC type not implemented!")
        }
    }
    
    func readROM(_ address: Int) -> Byte {
        switch address {
            case 0x0000 ..< 0x4000: return rom[address]
            case 0x4000 ..< 0x8000: return rom[address & 0x3FFF + romOffset]
            default: return 0
        }
    }
    
    func readRAM(_ address: Int) -> Byte {
        return ram[address & 0x1FFF + ramOffset]
    }
    
    func writeROM(_ address: Int, value: Byte) {
        switch address {
            case 0x0000 ..< 0x2000: //Switch RAM extension
                switch mbc {
                    case .noMBC, .mbc1: break
                    case .mbcExternalRAM, .mbcBattery:
                        ramOn = value & 0xA == 0xA
                        if !ramOn { saveRAM() }
                }
            case 0x2000 ..< 0x4000: //Set lower bits ROM bank
                switch mbc {
                    case .noMBC: break
                    case .mbc1, .mbcExternalRAM, .mbcBattery:
                        //set lower 5 bits of the ROM bank, 0 is 1
                        let val = max(Int(value) & 0x1F, 1)
                        romBank = (romBank & 0x60 + val) % romSize
                        romOffset = romBank * 0x4000
                }
            case 0x4000 ..< 0x6000: //Set RAM bank or higher bits ROM bank
                switch mbc {
                    case .noMBC: break
                    case .mbc1, .mbcExternalRAM, .mbcBattery:
                        let val = Int(value) & 0b11
                        if mode == .rom {
                            romBank = (romBank & 0x1F + val << 5) % romSize
                            romOffset = romBank * 0x4000
                        } else {
                            ramBank = val
                            ramOffset = ramBank * 0x2000
                        }
                }
            case 0x6000 ..< 0x8000: //Set ROM/RAM extension mode
                switch mbc {
                    case .noMBC, .mbc1: break
                    case .mbcExternalRAM, .mbcBattery:
                        mode = value == 0 ? .rom : .ram
                }
            default: break
        }
    }
    
    func writeRAM(_ address: Int, value: Byte) {
        return ram[address & 0x1FFF + ramOffset] = value
    }
    
    func saveRAM() {
        if ramSize != 0 && mbc == .mbcBattery
            && createFolderAt("gbemusav", location: .documentDirectory) {
            if saveBinaryFile("gbemusav/" + name + ".sav", location: .documentDirectory, buffer: ram) {
                print("Successfully saved " + name + ".sav save file!")
            }
            if saveBinaryFile("gbemusav/" + name + " backup.sav", location: .documentDirectory, buffer: ram) {
                print("Plus backup file")
            }
        }
    }
    
    func loadRAM() {
        if ramSize != 0 && mbc == .mbcBattery {
            if loadBinaryFile("gbemusav/" + name + ".sav", location: .documentDirectory, buffer: &ram) {
                print("Successfully loaded " + name + ".sav save file!")
            }
        }
    }
}
