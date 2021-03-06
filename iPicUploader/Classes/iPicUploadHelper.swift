//
//  iPicUploadHelper.swift
//  iPicUploadImageDemo
//
//  Created by Jason Zheng on 8/31/16.
//  Copyright © 2016 Jason Zheng. All rights reserved.
//

import Cocoa

public class iPicUploadHelper {
  private static let iPicBundleIdentifier = "net.toolinbox.ipic"
  private static let iPicURLScheme = "ipic://"
  
  // MARK: Static Method
  
  static func isiPicRunning() -> Bool {
    return !NSRunningApplication.runningApplicationsWithBundleIdentifier(iPicBundleIdentifier).isEmpty
  }
  
  static func launchiPic() -> NSError? {
    guard !isiPicRunning() else {
      return nil
    }
    
    do {
      let schemeURL = NSURL(string: iPicURLScheme)!
      try NSWorkspace.sharedWorkspace().openURL(schemeURL, options: .WithoutActivation, configuration: [:])
      return nil
    } catch {
      return iPicUploadError.iPicNotInstalled
    }
  }
  
  static func generateiPicImage(imageFilePath: String) -> (iPicImage?, NSError?) {
    guard let data = NSData(contentsOfFile: imageFilePath) else {
      return (nil, iPicUploadError.FileInaccessable)
    }
    
    guard let _ = NSImage(data: data) else {
      return (nil, iPicUploadError.InvalidImageFile)
    }
    
    let image = iPicImage(imageFilePath: imageFilePath)
    image.imageData = data
    
    return (image, nil)
  }
  
  static func generateiPicImage(image: NSImage) -> (iPicImage?, NSError?) {
    guard let imageData = imageDataOf(image, type: .NSJPEGFileType) else {
      return (nil, iPicUploadError.Unknown) // Should not happen
    }
    
    let image = iPicImage(imageData: imageData)
    
    return (image, nil)
  }
  
  static public func generateImageDataListFrom(pasteboard: NSPasteboard) -> [NSData] {
    var imageDataList = [NSData]()
    
    if let pasteboardItems = pasteboard.pasteboardItems {
      for pasteboardItem in pasteboardItems {
        if let imageData = generateImageDataFrom(pasteboardItem) {
          imageDataList.append(imageData)
        }
      }
    }
    
    return imageDataList
  }
  
  static private func generateImageDataFrom(pasteboardItem: NSPasteboardItem) -> NSData? {
    for type in pasteboardItem.types {
      if let data = pasteboardItem.dataForType(type) {
        if type == String(kUTTypeFileURL) {
          let url = NSURL(dataRepresentation: data, relativeToURL: nil)
          if let imageData = NSData(contentsOfURL: url), _ = NSImage(data: imageData) {
            return imageData
          }
          
        } else if let _ = NSImage(data: data) {
          return data
        }
      }
    }
    
    return nil
  }
  
  static func imageDataOf(image: NSImage, type: NSBitmapImageFileType) -> NSData? {
    guard let imageData = image.TIFFRepresentation else {
      return nil
    }
    
    if type == NSBitmapImageFileType.NSTIFFFileType {
      return imageData
    }
    
    guard let imageRep = NSBitmapImageRep(data: imageData) else {
      return nil
    }
    
    return imageRep.representationUsingType(type, properties: [:])
  }
  
  static func delay(delay:Double, closure:()->()) {
    dispatch_after(
      dispatch_time(
        DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC))
      ),
      dispatch_get_main_queue(), closure)
  }
}