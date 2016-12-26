//
//  MainView.swift
//  gbemu
//
//  Created by Otis Carpay on 16/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import AppKit

let bitSize = 4;

@IBDesignable class ScreenView: NSView, GPUOutputReceiver {
    var image = [Byte](repeating: 0, count: Int(160*144*4))
    var context: CGContext?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        context = CGContext(
            data: UnsafeMutableRawPointer(mutating: image),
            width: 160,
            height: 144,
            bitsPerComponent: 8,
            bytesPerRow: 4 * 160,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        context?.setShouldAntialias(false)
        
        if let current = NSGraphicsContext.current()?.cgContext {
            if let cgImage = context?.makeImage() {
                current.draw(cgImage, in: CGRect(x: 0, y: 0, width: 160*3, height: 144*3))
            }
        }
    }
    
    func putImageData(_ data: [Byte]) {
        image = data
        display()
    }
}
