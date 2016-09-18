//
//  MainView.swift
//  gbemu
//
//  Created by Otis Carpay on 16/08/15.
//  Copyright © 2015 Otis Carpay. All rights reserved.
//

import AppKit

struct RGB {
    var r: Byte
    var g: Byte
    var b: Byte
}

@IBDesignable class ScreenView: NSView, GPUOutputReceiver {
    var image = [Byte](count:Int(160*144*3), repeatedValue: 0)
    
    override func drawRect(dirtyRect: NSRect) {
        let context: CGContext! = NSGraphicsContext.currentContext()?.CGContext
        let data = NSData(bytes: image, length: image.count * sizeof(RGB))
        let provider = CGDataProviderCreateWithCFData(data)
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let info = CGBitmapInfo.ByteOrderDefault
        
        let finalImage = CGImageCreate(160, 144, 8, 24, 3 * 160, colorspace, info, provider, nil, false, .RenderingIntentDefault);
        
        CGContextSetInterpolationQuality(context, .None);
        CGContextSetShouldAntialias(context, false);
        CGContextScaleCTM(context, 3, 3);
        
        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: 160, height: 144), finalImage);
    }
    
    func putImageData(data: [Byte]) {
        image = data
        display()
    }
}