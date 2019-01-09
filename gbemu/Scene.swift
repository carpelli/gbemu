//
//  Scene.swift
//  gbemu
//
//  Created by Otis Carpay on 08/01/2019.
//  Copyright © 2019 Otis Carpay. All rights reserved.
//

import SpriteKit

let screenWidth = 160
let screenHeight = 144
let ratio = Double(screenHeight) / Double(screenWidth)

class Scene: SKScene, GPUOutputReceiver {
    weak var gameboy: Gameboy?
    
    var screen: SKSpriteNode?
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        scaleMode = .aspectFill
        isUserInteractionEnabled = false
        screen = SKSpriteNode()
        screen!.size = CGSize(width: 1, height: ratio)
        screen!.position = CGPoint(x: 0.5, y: 0.5)
        self.addChild(screen!)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let gameboy = gameboy else { return }
        
//        print("Refresh")
        gameboy.runFrame()
    }
    
    func putImageData(_ data: [Byte]) {
        let image = data
        if let context = CGContext(
                data: UnsafeMutableRawPointer(mutating: image),
                width: screenWidth,
                height: screenHeight,
                bitsPerComponent: 8,
                bytesPerRow: 4 * screenWidth,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            ) {
            let texture = SKTexture(cgImage: context.makeImage()!)
            texture.filteringMode = .nearest
            screen!.texture = texture
        }
    }
}
