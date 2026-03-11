//
//  main.swift
//  COMP4932-Assignment1
//
//  Blends two images together.
//
//  Created by Justin Cardas on 2026-03-10.
//

import Foundation
import CoreGraphics
import UniformTypeIdentifiers
import ImageIO

func blendImages(w0Path: String, w1Path: String, outputPath: String, time: Double) {
    
    // Apple requires URL objects instead of plain text string paths.
    let w0URL = URL(fileURLWithPath: w0Path)
    let w1URL = URL(fileURLWithPath: w1Path)
    let outputURL = URL(fileURLWithPath: outputPath)
    
    // This guard function safely tries to load the images from the URL's
    // If any part of the guard block fails, the else block is executed.
    guard let source0 = CGImageSourceCreateWithURL(w0URL as CFURL, nil),
          let cgImage0 = CGImageSourceCreateImageAtIndex(source0, 0, nil),
          let source1 = CGImageSourceCreateWithURL(w1URL as CFURL, nil),
          let cgImage1 = CGImageSourceCreateImageAtIndex(source1, 0, nil) else {
        fatalError("Couldn't load images.")
    }
    
    // Store the image sizes for calculations later.
    let width = cgImage0.width
    let height = cgImage0.height
    
    // Prepare the memory for pixels
    // Tell the system we are working with RGB
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    // Each pixel is made R,G,B and Alpha bytes.
    let bytesPerPixel: Int = 4
    let bytesPerRow: Int = width * bytesPerPixel
    let totalBytes: Int = bytesPerRow * height
    
    // Create empty buffers to hold the raw pixel data
    // UInt 8 is an unsigned 8 bit integer, which is a num from 0-255
    var pixels0 = [UInt8](repeating: 0, count: totalBytes) // repeating: 0 puts the number 0 (totalBytes) number of times.
    var pixels1 = [UInt8](repeating: 0, count: totalBytes)
    var outPixels = [UInt8](repeating: 0, count: totalBytes)
    
    // Define the layout of pixels in memory
    // This tells the system to set the Alpha byte at the end of the sequence (RGB,A)
    // Premultiplied means the Alpha math is done before the pixel is saved to memory.
    let contextInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    
    // CGContext is like a canvas built using the data defined before.
    // Here we define the parameters for each canvas.
    // The data is linked to our pixel arrays, so any changes made are
    // linked to the original arrays.
    guard
        let context0 = CGContext(data: &pixels0,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: 8,
                                 bytesPerRow: bytesPerRow,
                                 space: colorSpace,
                                 bitmapInfo: contextInfo),
        let context1 = CGContext(data: &pixels1,
                                 width: width,
                                 height: height,
                                 bitsPerComponent: 8,
                                 bytesPerRow: bytesPerRow,
                                 space: colorSpace,
                                 bitmapInfo: contextInfo)
    else {
        fatalError("Couldn't create image drawing contexts.")
    }
    
    // Draw the images into the canvases.
    // Basically extracts the image data and turns it into raw number
    // data in the arrays.
    context0.draw(cgImage0, in: CGRect(x: 0,
                                       y: 0,
                                       width: width,
                                       height: height))
    context1.draw(cgImage1, in: CGRect(x: 0,
                                       y: 0,
                                       width: width,
                                       height: height))
    
    // Now we can blend the image data together using the data extracted
    // from the images.
    let weight1 = time          // As time increases, image 1 becomes more visible
    let weight0 = 1.0 - weight1 // The inverse happens to image 0. (less visible)
    
    // Loop through each byte in the image arrays
    for i in 0..<totalBytes {
        
        // Check if the current byte is the Alpha (Opacity) channel.
        // Every 4th byte is the Alpha
        if (i + 1) % 4 == 0 {
            outPixels[i] = 255 // Set the opacity to maximum so final image is fully visible
        } else {
            // Otherwise this is a colour value
            
            // Extract each colour from this pixel of each image.
            let p0 = Double(pixels0[i])
            let p1 = Double(pixels1[i])
            
            // Multiply each colour value by its weight at this time, then add them together
            let blended = (p0 * weight0) + (p1 * weight1)
            
            // Ensure the resulting number isn't outside the bounds of the UInt8 (0-255)
            outPixels[i] = UInt8(min(max(blended, 0), 255))
        }
        
    }
}



// Finally, blend the images.

let workingDirectory = "./img/"

// Loop through each time step (each image)
for img_step in 1...8 {
    let time:Double = Double(img_step) / 9.0
    
    let w0FileName = workingDirectory + "W0.t\(img_step).jpg"
    let W1FileName = workingDirectory + "W1.t\(img_step).jpg"
    let outputFileName = workingDirectory + "O.t\(img_step).jpg"
    
    blendImages(w0Path: w0FileName,
                w1Path: W1FileName,
                outputPath: outputFileName,
                time: time)
}
