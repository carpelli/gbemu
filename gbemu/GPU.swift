
//
//  GPU.swift
//  gbemu
//
//  Created by Otis Carpay on 15/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import Dispatch

protocol GPUOutputReceiver {
    func putImageData(_ data: [Byte])
}

let colors: [[Byte]] = [
    [255, 255, 255],
    [170, 170, 170],
    [85, 85, 85],
    [0, 0, 0]
]

final class GPU {
    enum Mode: Byte {
        case hBlank = 0, vBlank, oam, vram
    }
    
    var vram = [Byte](repeating: 0xFF, count: 0x2000)
    var oam = OAM()
    
    var tileset =
    [[[Int]]](
        repeating: [[Int]](
            repeating: [0, 0, 0, 0, 0, 0, 0, 0],
            count: 8
        ),
        count: 384
    )
    
    var image = [Byte](repeating: 0, count: 160*144*4)
    let screen: GPUOutputReceiver
    let system: Gameboy
    
    private var mode = Mode.oam
    private var modeClock = 0
    private var line: Byte = 0
    private var bgMap = false
    private var windowMap = false
    private var switchBG = false
    private var switchObj = false
    private var switchWindow = false
    private var bgTile = 1
    private var switchLCD = false
    private var lineCompare: Byte = 0
    private var tallSprites = false
    
    private var intHBlankEnable = false
    private var intVBlankEnable = false
    private var intOAMEnable = false
    private var intCoEnable = false
    
    private var windowX = 0
    private var windowY = 0
    
    private var scanY: Byte = 0
    private var scanX: Byte = 0
    
    private var bgPalette = colors
    private var objPalettes = [
        colors,
        colors
    ]
    
    init(system: Gameboy, screen: GPUOutputReceiver) {
        self.system = system
        self.screen = screen
    }
    
    func step(_ m: Int) {
        modeClock += m
        
        switch mode {
            //OAM read mode, scanline active FIXME what happens during these modes
            case .oam where modeClock > 20:
                modeClock -= 20
                mode = .vram
            
            //VRAM read mode, scanline active
            case .vram where modeClock > 43:
                modeClock -= 43
                mode = .hBlank
                if (intHBlankEnable) { system.cpu.requestInterrupt(.lcdStat) }
                
                //Write scanline to buffer
                renderScan()
            
            //hblank, after last hblank, push screen to bitmap
            case .hBlank where modeClock > 51:
                modeClock -= 51
                line += 1
                if (intCoEnable && line == lineCompare) { system.cpu.requestInterrupt(.lcdStat) }
                
                if line == 144 {
                    screen.putImageData(image)
                    mode = .vBlank
                    if (intVBlankEnable) { system.cpu.requestInterrupt(.lcdStat) }
                    system.cpu.requestInterrupt(.vBlank)
                } else {
                    mode = .oam
                    if (intOAMEnable) { system.cpu.requestInterrupt(.lcdStat) }
                }
            
            //vblank
            case .vBlank where modeClock > 114:
                modeClock -= 114
                line += 1
                if (intCoEnable && line == lineCompare) { system.cpu.requestInterrupt(.lcdStat) }
                
                if line == 154 {
                    mode = .oam
                    if (intOAMEnable) { system.cpu.requestInterrupt(.lcdStat) }
                    line = 0
                }
            
            default: break
        }
    }
    
    func readByte(_ address: Word) -> Byte {
        switch(address)
        {
            // LCD Control
            case 0xFF40:
                return
                    (switchBG  ?    0x01 : 0x00) |
                    (switchObj ?    0x02 : 0x00) |
                    (tallSprites ?  0x04 : 0x00) |
                    (bgMap     ?    0x08 : 0x00) |
                    (bgTile == 1 ?  0x10 : 0x00) |
                    (switchWindow ? 0x20 : 0x00) |
                    (windowMap ?    0x40 : 0x00) |
                    (switchLCD ?    0x80 : 0x00)
            
            case 0xFF41:
                return
                    mode.rawValue                       |
                    (line == lineCompare ? 0x04 : 0x00) |
                    (intHBlankEnable     ? 0x08 : 0x00) |
                    (intVBlankEnable     ? 0x10 : 0x00) |
                    (intOAMEnable        ? 0x20 : 0x00) |
                    (intCoEnable         ? 0x40 : 0x00)
            
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
                switchBG =     value & 0x01 == 0x01
                switchObj =    value & 0x02 == 0x02
                tallSprites =  value & 0x04 == 0x04
                bgMap =        value & 0x08 == 0x08
                bgTile =       value & 0x10 == 0x10 ? 1 : 0
                switchWindow = value & 0x20 == 0x20
                windowMap =    value & 0x40 == 0x40
                switchLCD =    value & 0x80 == 0x80
            
            // LCD Status
            case 0xFF41:
                intHBlankEnable = value & 0x08 > 0
                intVBlankEnable = value & 0x10 > 0
                intOAMEnable    = value & 0x20 > 0
                intCoEnable     = value & 0x40 > 0
                
            // Scroll Y
            case 0xFF42: scanY = value
                
            // Scroll X
            case 0xFF43: scanX = value
            
            case 0xFF45: lineCompare = value
            case 0xFF46: system.cpu.mmu.transferDMA(value)
                
            //Background palette
            case 0xFF47:
                for i in 0..<4 {
                    bgPalette[i] = colors[Int(value >> Byte(2*i) & 0b11)]
                }
            
            //Object palettes
            case 0xFF48, 0xFF49:
                let paletteIndex = Int(address - 0xFF48)
                for i in 0..<4 {
                    objPalettes[paletteIndex][i] = colors[Int(value >> Byte(2*i) & 0b11)]
                }
            case 0xFF4A:
                windowY = Int(value)
            case 0xFF4B:
                windowX = Int(value) - 7
            
        default: break
        }
    }
    
    func renderScan() {
        //use by sprite renderer
        var scanrow = [Int](repeating: 0, count: 160)
        
        if switchBG {
            //VRAM offset for the tilemap ????
            var mapOffset: Word = bgMap ? 0x1C00 : 0x1800
            
            //Which line of tiles to use in the map
            mapOffset += (Word(line &+ scanY) / 8) * 32
            
            //Which tile to start with in the map line
            var lineOffset = Int(scanX / 8)
            
            //Which line of pixels to use in the tiles
            let y = (line &+ scanY) & 7
//            let y = line & 7
            
            //Where in the tile line to start
            var x = scanX & 7
//            var x = 0
            
            //Where to render on the bitmap
            var bitmapOffset = Int(line) * 160 * 4
            
            //Read the tile index from the background map
            var tile = Int(vram[Int(mapOffset) + lineOffset])
            
            // If the tile data set in use is #0, the
            // indices are signed; calculate a real tile offset
            if bgTile == 0 && tile < 128 {
                tile += 256
            }
            
            for i in 0..<160 {
                let color = bgPalette[tileset[tile][Int(y)][Int(x)]]
                
                scanrow[i] = tileset[tile][Int(y)][Int(x)]
                
                //Plot pixel to bitmap
                image[bitmapOffset + 0] = color[0]
                image[bitmapOffset + 1] = color[1]
                image[bitmapOffset + 2] = color[2]
                bitmapOffset += 4
                
                //When this tile ends, read another
                x += 1
                if x == 8 {
                    x = 0
                    lineOffset = (lineOffset + 1) & 0x1F
                    tile = Int(vram[Int(mapOffset) + lineOffset])
                    if bgTile == 0 && tile < 128 {
                        tile += 256
                    }
                }
            }
        }
        
        if switchWindow && Int(line) >= windowY {
            var mapOffset: Word = windowMap ? 0x1C00 : 0x1800
            let windowLine = Int(line) - windowY
            
            if windowLine >= 0 {
                mapOffset += (Word(windowLine) / 8) * 32
                let y = windowLine & 7
                var bitmapOffset = Int(line) * 160 * 4
                
                var x = 0
                var lineOffset = 0
                var tile = Int(vram[Int(mapOffset)])
                if bgTile == 0 && tile < 128 {
                    tile += 256
                }
                
                for i in windowX..<160 {
                    if i >= 0 {
                        let color = bgPalette[tileset[tile][y][x]]
                        
                        scanrow[i] = tileset[tile][Int(y)][Int(x)]
                        
                        image[bitmapOffset + 0] = color[0]
                        image[bitmapOffset + 1] = color[1]
                        image[bitmapOffset + 2] = color[2]
                        bitmapOffset += 4
                    }
                    
                    x += 1
                    if x == 8 {
                        x = 0
                        lineOffset = (lineOffset + 1) & 0x1F
                        tile = Int(vram[Int(mapOffset) + lineOffset])
                        if bgTile == 0 && tile < 128 {
                            tile += 256
                        }
                    }
                }
            }
        }
        
        if switchObj {
            var spriteCount = 0
            let height = tallSprites ? 16 : 8
            
            for object in oam.objects.sorted(by: { $0.x < $1.x }).reversed() {
                guard case object.y ..< object.y + height = Int(line) else { continue }
                
                guard spriteCount < 10 else { break }
                spriteCount += 1
                
                let bitmapOffset = Int(line) * 160 * 4
                
                //Flip what needs to be flipped
                var tileRowIndex = Int(line) - object.y
                if object.yFlip { tileRowIndex = height - 1 - tileRowIndex }
                
                var tile = object.tile
                //Fix for tall sprites
                if tallSprites {
                    //tile |= 0xFE
                    if tileRowIndex > 7 {
                        tileRowIndex -= 8
                        tile += 1
                    }
                }
                
                var tileRow = tileset[tile][tileRowIndex]
                if object.xFlip { tileRow = tileRow.reversed() }
                
                for x in 0..<8 {
                    let spriteOffset = (object.x + x) * 4
                    
                    if 0..<160 ~= object.x + x &&
                        tileRow[x] != 0 &&
                        (object.priority || scanrow[object.x + x] == 0) //FIXME
                    {
                        let color = objPalettes[object.palette ? 1 : 0][tileRow[x]]
                        
                        image[bitmapOffset + spriteOffset + 0] = color[0]
                        image[bitmapOffset + spriteOffset + 1] = color[1]
                        image[bitmapOffset + spriteOffset + 2] = color[2]
                    }
                }
            }
        }
        
        //TODO: switchLCD
    }
    
    func updateTile(_ address: Word, value: Byte) {
        guard address - 0x8000 < 0x1800 else {
            return
        }
        
        //Get the 'base address' for this tile row
        let address = Int(address & 0x1FFF)
        
        //Work out which tile and row was updated
        let tile = address >> 4
        
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
    
    deinit {
        print("GPU released")
    }
}
