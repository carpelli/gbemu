//
//  DocumentController.swift
//  gbemu
//
//  Created by Otis Carpay on 30/01/2017.
//  Copyright © 2017 Otis Carpay. All rights reserved.
//

import Cocoa

class DocumentController: NSDocumentController {
    var loadROM: ((URL) -> ())!
    
    override func openDocument(withContentsOf url: URL, display displayDocument: Bool, completionHandler: @escaping (NSDocument?, Bool, Error?) -> Void) {
        loadROM(url)
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
