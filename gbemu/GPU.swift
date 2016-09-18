//
//  GPU.swift
//  gbemu
//
//  Created by Otis Carpay on 15/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Foundation

protocol GPUOutputReceiver {
    func putImageData(data: [Byte])
}

class GPU {
    enum Mode: Byte {
        case HBlank = 0, VBlank, OAM, VRAM
    }
    
    var tileset =
    [[[Int]]](count: 256, repeatedValue:
        [[Int]](count: 8, repeatedValue: [0, 0, 0, 0, 0, 0, 0, 0])
    )

    var vram = [Byte](count: 0x2000, repeatedValue: 0)
    var oam  = [Byte](count: 0xA0,  repeatedValue: 0)
    
    var image = [Byte](count: 160*144*4, repeatedValue: 0)
    let screen: GPUOutputReceiver
    
    private var mode = Mode.HBlank
    private var modeClock = 0
    private var totalClock = 0
    private var line: Byte = 0
    private var bgMap = false
    private var switchBG = false
    private var bgTile = 0
    private var switchLCD = false
    private var lineCompare: Byte = 0
    
    private var scanY: Byte = 0
    private var scanX: Byte = 0
    
    private var palette: [[Byte]] = [
        [0, 0, 0],
        [85, 85, 85],
        [170, 170, 170],
        [255, 255, 255]
    ]
    
    init(screen: GPUOutputReceiver) {
        self.screen = screen
    }
    
    func step(t: Int) {
        modeClock += t
        totalClock += t
        
        switch mode {
            //OAM read mode, scanline active
            case .OAM:
                if modeClock > 80 {
                    //Enter scanline mode 3
                    modeClock = 0
                    mode = .VRAM
                }
            //VRAM read mode, scanline active
            case .VRAM:
                if modeClock > 172 {
                    //Enter hblank
                    modeClock = 0
                    mode = .HBlank
                    
                    //Write scanline to buffer
                    renderScan()
                }
            //hblank, after last hblank, push screen to bitmap
            case .HBlank:
                if modeClock > 204 {
                    modeClock = 0
                    ++line
                    
                    if line == 144 {
                        screen.putImageData(image)
                        mode = .VBlank
                    } else {
                        mode = .OAM
                    }
                }
            //vblank
            case .VBlank:
                if modeClock > 456 {
                    modeClock = 0
                    ++line
                    
                    if line == 154 {
                        mode = .OAM
                        line = 0
                    }
                }
        }
    }
    
    func readByte(address: Word) -> Byte {
        switch(address)
        {
            // LCD Control
            case 0xFF40:
                return
                    (switchBG  ? 0x01 : 0x00) |
                    (bgMap     ? 0x08 : 0x00) |
                    (bgTile==1 ? 0x10 : 0x00) |
                    (switchLCD ? 0x80 : 0x00)
            
            case 0xFF41:
                return
                    (line == lineCompare ? 0x04 : 0x00) |
                    mode.rawValue
                
            // Scroll Y
            case 0xFF42:
                return scanY;
                
            // Scroll X
            case 0xFF43:
                return scanX;
                
            // Current scanline
            case 0xFF44:
                return line;
            
            case 0xFF45:
                return lineCompare
            
            default: return 0
        }
    }
    
    func writeByte(address: Word, value: Byte) {
        switch(address)
        {
            // LCD Control
            case 0xFF40:
                switchBG =  value & 0x01 == 0x01
                bgMap =     value & 0x08 == 0x08
                bgTile =     0x10 & 0x10 >> 4
                switchLCD = value & 0x80 == 0x80
            
            // LCD Status
            case 0xFF41: return
                
            // Scroll Y
            case 0xFF42:
                scanY = value
                
            // Scroll X
            case 0xFF43:
                scanX = value
            
            case 0xFF45:
                lineCompare = value
                
            //Background palette
            case 0xFF47:
                for i in 0..<4 {
                    switch ((value >> Byte(i*2)) & 0b11) {
                        case 0: palette[i] = [255,255,255,255]
                        case 1: palette[i] = [192,192,192,255]
                        case 2: palette[i] = [ 96, 96, 96,255]
                        case 3: palette[i] = [  0,  0,  0,255]
                        default: fatalError()
                    }
                }
            
            default: 0
        }
    }
    
    func renderScan() {
        //VRAM offset for the tilemap ????
        var mapOffset: Word = bgMap ? 0x1C00 : 0x1800
        
        //Which line of tiles to use in the map
        mapOffset += (Word(line &+ scanY) / 8) * 32
        
        //Which tile to start with in the map line
        var lineOffset = Int(scanX / 8)
        
        //Which line of pixels to use in the tiles
        let y = (line &+ scanY) & 7
        
        //Where in the tile line to start
        var x = scanX & 7
        
        //Where to render on the bitmap
        var bitmapOffset = Int(line) * 160 * 3
        
        //Read the tile index from the background map
        var colour: [Byte]
        var tile = Int(vram[Int(mapOffset) + lineOffset])
        
        // If the tile data set in use is #1, the
        // indices are signed; calculate a real tile offset
        if (bgTile == 1 && tile < 128) {
            tile += 256
            fatalError()
        }
        
        for _ in 0..<160 {
            colour = palette[tileset[tile][Int(y)][Int(x)]]
            
            //Plot pixel to bitmap
            image[bitmapOffset + 0] = colour[0]
            image[bitmapOffset + 1] = colour[1]
            image[bitmapOffset + 2] = colour[2]
            //screen[bitmapOffset + 3] = colour[3]
            bitmapOffset += 3
            
            //When this tile ends, read another
            ++x
            if x == 8 {
                x = 0
                lineOffset = (lineOffset + 1) & 0x1F
                tile = Int(vram[Int(mapOffset) + lineOffset])
                if bgTile == 1 && tile < 128 {
                    tile += 256
                }
            }
        }
    }
    
    func updateTile(address: Word, value: Byte) {
        guard address & 0x1000 == 0 else {
            return
        }
        
        //Get the 'base address' for this tile row
        let address = Int(address & 0x1FFF)
        
        //Work out which tile and row was updated
        let tile = (address >> 4) & 0xFF
        
        var sx: Byte
        for y in 0..<8 {
            let highLine = vram[(tile << 4) + (y << 1)]
            let lowLine =  vram[(tile << 4) + (y << 1) + 1]
            for x in 0..<8 {
                //Find bit index for this pixel
                sx = 1 << Byte(7-x)
                tileset[tile][y][x] =
                    Int((highLine & sx) > 0 ? 1 : 0) |
                    Int((lowLine  & sx) > 0 ? 2 : 0)
            }
        }
    }
}