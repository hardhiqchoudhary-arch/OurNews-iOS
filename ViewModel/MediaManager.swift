//
//  MediaManager.swift
//  OurNews
//
//  Created by Hardhiq Choudhary on 13/11/25.
//


import SwiftUI
import UIKit

class MediaManager: ObservableObject {
    
    static let shared = MediaManager()
    
    private init() {}
    
    // Save image to local storage and return filename
    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let filename = UUID().uuidString + ".jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    // Load image from local storage
    func loadImage(filename: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    // Delete image from local storage
    func deleteImage(filename: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    // Get documents directory
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Convert local filename to full path for display
    func getImageURL(filename: String) -> URL? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        return fileURL
    }
}

// Helper extension for UIImage
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
