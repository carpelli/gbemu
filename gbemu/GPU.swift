//
//  GPU.swift
//  gbemu
//
//  Created by Otis Carpay on 15/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

protocol GPUOutputReceiver {
    func putImageData(_ data: [Byte])
}

class GPU {
    enum Mode: Byte {
        case hBlank = 0, vBlank, oam, vram
    }
    
    var tileset =
    [[[Int]]](
        repeating: [[Int]](
            repeating: [0, 0, 0, 0, 0, 0, 0, 0],
            count: 8
        ),
        count: 256
    )

    var vram = [Byte](repeating: 0, count: 0x2000)
    var oam  = [Byte](repeating: 0,  count: 0xA0)
    
    var image = [Byte](repeating: 0, count: 160*144*bitSize)
    let screen: GPUOutputReceiver
    let system: Gameboy
    
    private var mode = Mode.oam
     var modeClock = 0
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
    
    init(system: Gameboy, screen: GPUOutputReceiver) {
        self.system = system
        self.screen = screen
    }
    
    func step(_ t: Int) {
        modeClock += t
        totalClock += t
        
        switch mode {
            //OAM read mode, scanline active
            case .oam:
                if modeClock > 80 {
                    //Enter scanline mode 3
                    modeClock -= 80
                    mode = .vram
                }
            //VRAM read mode, scanline active
            case .vram:
                if modeClock > 172 {
                    //Enter hblank
                    modeClock -= 172
                    mode = .hBlank
                    
                    //Write scanline to buffer
                    renderScan()
                }
            //hblank, after last hblank, push screen to bitmap
            case .hBlank:
                if modeClock > 204 {
                    modeClock -= 204
                    line += 1
                    
                    if line == 144 {
                        screen.putImageData(image)
                        mode = .vBlank
                        system.cpu.mmu.iFlag[0] = true
                    } else {
                        mode = .oam
                    }
                }
            //vblank
            case .vBlank:
                if modeClock > 456 {
                    modeClock -= 456
                    line += 1
                    
                    if line == 154 {
                        mode = .oam
                        line = 0
                    }
                }
        }
    }
    
    func readByte(_ address: Word) -> Byte {
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
    
    func writeByte(_ address: Word, value: Byte) {
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
            
            default: break
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
        var bitmapOffset = Int(line) * 160 * 4
        
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
            bitmapOffset += bitSize
            
            //When this tile ends, read another
            x += 1
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
    
    func updateTile(_ address: Word, value: Byte) {
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
