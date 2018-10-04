//
//  NSImage.swift
//  BeagleIM
//
//  Created by Andrzej Wójcik on 14.09.2018.
//  Copyright © 2018 HI-LOW. All rights reserved.
//

import AppKit

extension NSImage {
    
    func rounded() -> NSImage {
        return rounded(radius: min(size.width, size.height)/2);
    }
    
    func rounded(radius: CGFloat) -> NSImage {
        guard let cgImage = self.cgImage, let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else {
            return self;
        }
        
        let rect = NSRect(origin: .zero, size: size);
        
        context.beginPath();
        context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil));
        context.closePath();
        context.clip();
        context.draw(cgImage, in: rect);
        
        guard let composedImage = context.makeImage() else {
            return self;
        }
        
        return NSImage(cgImage: composedImage, size: size);
    }

    func scaledToPng(to size: NSSize) -> Data? {
        guard let cgImage = self.cgImage else {
            return nil;
        }
        let newRep = NSBitmapImageRep(cgImage: cgImage);
        newRep.size = size;
        return newRep.representation(using: .png, properties: [:]);
    }

    func scaledToPng(to maxWidthOrHeight: CGFloat) -> Data? {
        let maxDimmension = max(self.size.height, self.size.width);
        let scale = maxDimmension / maxWidthOrHeight;
        let expSize = NSSize(width: self.size.width / scale, height: self.size.height / scale);
        return scaledToPng(to: size);
    }
}

fileprivate extension NSImage {

    var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size);
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil);
    }
    
}
