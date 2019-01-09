//
//  Screen.swift
//  gbemu
//
//  Created by Otis Carpay on 29/12/2016.
//  Copyright © 2016 Otis Carpay. All rights reserved.
//

import Cocoa
import OpenGL.GL

class Screen: NSOpenGLView, GPUOutputReceiver {
    
    let screenWidth = 160
    let screenHeight = 144
    let texSize: Int32 = 256
    
    var textureName = GLuint()
    var textureData: [GLubyte]
    
    required init?(coder aDecoder: NSCoder) {
        textureData = [GLubyte](repeating: GLubyte(255), count: Int(texSize*texSize)*4)
        super.init(coder: aDecoder)
        let attrs: [NSOpenGLPixelFormatAttribute] = [
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 32,
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile), NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core),
            0
        ]
        guard let pixelFormat = NSOpenGLPixelFormat(attributes: attrs) else {
            print("Pixel format could not be constructed.")
            return nil
        }
        self.pixelFormat = pixelFormat
        guard let context = NSOpenGLContext(format: pixelFormat, share: nil) else {
            print("Context could not be constructed.")
            return nil
        }
        self.openGLContext = context
        
        //  Set the context's swap interval parameter to 60Hz (i.e. 1 frame per swamp)
        self.openGLContext?.setValues([1], for: .swapInterval)
    }
    
    override var needsPanelToBecomeKey: Bool{
        get {
            return true
        }
    }
    override var acceptsFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func prepareOpenGL() {
        super.prepareOpenGL()
        // some init gl code here
        
        glGenTextures(1, &textureName);
        glBindTexture(UInt32(GL_TEXTURE_2D), textureName);
        glTexParameteri(UInt32(GL_TEXTURE_2D),UInt32(GL_TEXTURE_MIN_FILTER),GL_NEAREST);
        glTexParameteri(UInt32(GL_TEXTURE_2D),UInt32(GL_TEXTURE_MAG_FILTER),GL_NEAREST);
        glTexImage2D(UInt32(GL_TEXTURE_2D), 0, Int32(GL_RGBA), texSize, texSize, 0, UInt32(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), textureData);
    }
    
    override func reshape() {
        //TODO viewport reshaping
    }
    
    override func draw(_ dirtyRect: NSRect) {
        drawView()
    }
    
    func drawView() {
//          Grab a context, make it the active context for drawing, and then lock the focus
//          before making OpenGL calls that change state or data within objects.
        guard let context = self.openGLContext else {
            //  Just a filler error
            Swift.print("oops")
            return // todo return error?
        }

        context.makeCurrentContext()
//        context.lock()
        
        CGLLockContext(context.cglContextObj!)
        
        glClearColor(0, 0, 0, 0);
        glClear(UInt32(GL_COLOR_BUFFER_BIT))
        
        glEnable(UInt32(GL_TEXTURE_2D));
        glActiveTexture(UInt32(GL_TEXTURE0))
        glBindTexture(UInt32(GL_TEXTURE_2D), textureName);
        glTexImage2D(UInt32(GL_TEXTURE_2D), 0, Int32(GL_RGBA), texSize, texSize, 0, UInt32(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), textureData);
        
        let cord_right = Float(screenWidth)/Float(texSize)
        let cord_down = Float(screenHeight)/Float(texSize)
        
        glBegin(UInt32(GL_TRIANGLE_STRIP));
        glTexCoord2f(0.0, cord_down); glVertex2f(-1.0, -1.0);
        glTexCoord2f(cord_right, cord_down); glVertex2f(1.0, -1.0);
        glTexCoord2f(0.0, 0.0); glVertex2f(-1.0, 1.0);
        glTexCoord2f(cord_right, 0.0); glVertex2f(1.0, 1.0);
        glEnd();
        
        glDisable(UInt32(GL_TEXTURE_2D))
        
//        context.flushBuffer()
//        context.unlock()
        CGLFlushDrawable(context.cglContextObj!)
        CGLUnlockContext(context.cglContextObj!)
    }
    
    func putImageData(_ data: [Byte]) {
        for j in 0 ..< screenHeight {
            for i in 0 ..< screenWidth {
                let hue = data[(j*screenWidth+i)*4]
                textureData[(j*Int(texSize)+i)*4] = GLubyte(hue)
                textureData[(j*Int(texSize)+i)*4+1] = GLubyte(hue)
                textureData[(j*Int(texSize)+i)*4+2] = GLubyte(hue)
                textureData[(j*Int(texSize)+i)*4+3] = 255;
            }
        }
//        textureData = data
    }
}
