//
//  FileIO.swift
//  gbemu
//
//  Created by Otis Carpay on 04/01/2017.
//  Copyright © 2017 Otis Carpay. All rights reserved.
//

import Foundation

// Function for creating folder at specified location
func createFolderAt(_ folder: String, location: FileManager.SearchPathDirectory ) -> Bool {
    guard let locationUrl = FileManager().urls(for: location, in: .userDomainMask).first else { return false }
    do {
        try FileManager().createDirectory(at: locationUrl.appendingPathComponent(folder), withIntermediateDirectories: false, attributes: nil)
        return true
    } catch let error as NSError {
        // folder already exists return true
        if error.code == 17 || error.code == 516 {
            //LogD(folder + " already exists at " + locationUrl.absoluteString + " , ignoring")
            return true
        }
        print(folder + " couldn't be created at " + locationUrl.absoluteString)
        print(error.description)
        return false
    }
}

// Function for saving to binary file at specified location
func saveBinaryFile(_ name: String, location: FileManager.SearchPathDirectory, buffer: [UInt8]) -> Bool {
    guard
        let locationURL = FileManager().urls(for: location, in: .userDomainMask).first
        else {
            print("Failed to resolve path while saving file.")
            return false
    }
    let fileURL = locationURL.appendingPathComponent(name)
    let data = Data(bytes: UnsafePointer<UInt8>(buffer), count: buffer.count)
    return ((try? data.write(to: fileURL, options: [.atomic])) != nil)
}

// Function for loading from binary file at specified location
func loadBinaryFile(_ name: String, location: FileManager.SearchPathDirectory, buffer: inout [UInt8]) -> Bool {
    guard
        let locationURL = FileManager().urls(for: location, in: .userDomainMask).first
        else {
            print("Failed to find " + name + " file!")
            return false
    }
    
    let fileURL = locationURL.appendingPathComponent(name)
    
    guard
        let ramData = try? Data(contentsOf: fileURL)
        else {
            print("Failed to load " + name + " file!")
            return false
    }
    (ramData as NSData).getBytes(&buffer, length: ramData.count)
    return true
}
