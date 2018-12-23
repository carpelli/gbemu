//
//  OAM.swift
//  gbemu
//
//  Created by Otis Carpay on 27/12/2016.
//  Copyright © 2016 Otis Carpay. All rights reserved.
//

struct OAM {
    struct SpriteObject {
        var y = 0xFF
        var x = 0xFF
        var tile = 0xFF
        var options: Byte = 0xFF
        
        var priority: Bool { return options & 1 << 7 == 0 }
        var yFlip: Bool    { return options & 1 << 6 > 0 }
        var xFlip: Bool    { return options & 1 << 5 > 0 }
        var palette: Bool  { return options & 1 << 4 > 0 }
    }

    private(set) var oam = [Byte](repeating: 0xFF, count: 0xA0)
    private(set) var objects = [SpriteObject](repeating: SpriteObject(), count: 40)
    
    subscript(index: Int) -> Byte {
        get { return oam[index] }
        set {
            oam[index] = newValue
            
            switch index % 4 {
                case 0: objects[index/4].y =       Int(newValue) - 16
                case 1: objects[index/4].x =       Int(newValue) - 8
                case 2: objects[index/4].tile =    Int(newValue)
                case 3: objects[index/4].options = newValue
                default: break
            }
        }
    }
}
