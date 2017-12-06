//
// Created by Pavel Alexeev on 05/12/2017.
// Copyright (c) 2017 Pavel Alexeev. All rights reserved.
//

import Foundation
import UIKit

public class FastImageLoader
{
	public static let shared: FastImageLoader = FastImageLoader()
	
	private(set) var cache: NSCache<NSString, UIImage>
	private let saveQueue = DispatchQueue(label: "FastImageLoaderSaveQueue", qos: .background)
	
	public init()
	{
		cache = NSCache<NSString, UIImage>()
		cache.totalCostLimit = 10 * 1024 * 1024
		
		print("Caches URL: \(FastImageLoader.cachesPath)")
	}
	
	public func purgeCache()
	{
		//clear memory cache
		cache.removeAllObjects()
		
		//clear disk cache
		let contents = (try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: FastImageLoader.cachesPath), includingPropertiesForKeys: nil)) ?? []
		for url: URL in contents {
			if url.lastPathComponent.hasPrefix("cached_image_") {
				try? FileManager.default.removeItem(at: url)
			}
		}
	}
	
	public func loadImage(named name: String) -> UIImage?
	{
		if let cachedImage = cachedImage(named: name) {
//			print("loading image \(name) from memory cache")
			return cachedImage
		} else
		if let savedImage = savedImage(atPath: cachePath(forName: name)) {
//			print("loading image \(name) from disk cache")
			cache(image: savedImage, named: name)
			return savedImage
		} else {
//			print("loading image \(name) using UIImage(named:)")
			let image = UIImage(named: name)
			if image != nil {
				cache(image: image!, named: name)
				save(image: image!, path: cachePath(forName: name))
			}
			
			return image
		}
	}
	
	public func cachedImage(named name: String) -> UIImage?
	{
		return cache.object(forKey: NSString(string: name))
	}
	
	private func cache(image: UIImage, named name: String)
	{
		cache.setObject(image, forKey: NSString(string: name), cost: image.cost)
	}
	
	public func savedImage(atPath path: String) -> UIImage?
	{
		//TODO: image sizes!
		let width = 512
		let height = 512
		
		let length = width * height * 4
		let file = open(path, O_RDONLY)
		defer {
			close(file)
		}
		
		if file < 0 {
//			print("Could not open \(path)")
			return nil
		}
		
		guard let bytes = mmap(nil, length, PROT_READ, MAP_FILE | MAP_SHARED, file, 0) else {
			print("Could not mmap file \(path)")
			return nil
		}
		
		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
		let bitsPerComponent = 8
		let bytesPerPixel = 4
		let bitsPerPixel = bytesPerPixel * 8
		let bytesPerRow = width * bytesPerPixel
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		
		guard let dataProvider = CGDataProvider(
				dataInfo: nil,
				data: bytes, size: length, releaseData: { info, data, size in
			//data is released automatically
		}) else
		{
			print("Unable to create data provider for \(path)")
			return nil
		}
		
		guard let cgImage = CGImage(
				width: width,
				height: height,
				bitsPerComponent: bitsPerComponent,
				bitsPerPixel: bitsPerPixel,
				bytesPerRow: bytesPerRow,
				space: colorSpace,
				bitmapInfo: bitmapInfo,
				provider: dataProvider,
				decode: nil,
				shouldInterpolate: false,
				intent: .defaultIntent
		) else {
			print("Unable to create CGImage for \(path)")
			return nil
		}
		
		return UIImage(cgImage: cgImage)
	}

	private func save(image: UIImage, path: String)
	{
		saveQueue.async {
			guard var pixels = image.pixelData() else {
				print("Unable to get pixel data for \(path)")
				return
			}
			
			//print("Saving image \(name), \(pixels.count) bytes")
			
			let data = Data(bytes: &pixels, count: pixels.count)
			
			do {
				try data.write(to: URL(fileURLWithPath: path))
			} catch {
				print("Unable to write image data to \(path): \(error)")
			}
		}
	}
	
	private static let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].path
	
	private func cachePath(forName name: String) -> String
	{
		return "\(FastImageLoader.cachesPath)/cached_image_\(name).raw"
	}
}

extension UIImage
{
	fileprivate var cost: Int
	{
		return Int(size.width * scale) * Int(size.height * scale) * 4
	}

	fileprivate func pixelData() -> [UInt8]?
	{
		guard let cgImage = self.cgImage else {
			print("Unable to get pixel data (can't create CGImage)")
			return nil
		}
		//print("getting pixel data for image \(cgImage.width)×\(cgImage.height)")
		
		let dataSize = cgImage.width * cgImage.height * 4
		var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		guard let context = CGContext(
				data: &pixelData,
				width: Int(cgImage.width),
				height: Int(cgImage.height),
				bitsPerComponent: 8,
				bytesPerRow: 4 * Int(cgImage.width),
				space: colorSpace,
				bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else
		{
			print("Unable to get pixel data from image (can't create context)")
			return nil
		}
		
		context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
		
		return pixelData
	}
}
