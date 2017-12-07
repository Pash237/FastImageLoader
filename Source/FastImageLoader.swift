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
	}
	
	public func purgeCache()
	{
		//clear memory cache
		cache.removeAllObjects()
		
		//clear disk cache
		let contents = (try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: FastImageLoader.cachePath), includingPropertiesForKeys: nil)) ?? []
		for url: URL in contents {
			if url.lastPathComponent.hasPrefix("cached_image_") {
				try? FileManager.default.removeItem(at: url)
			}
		}
	}
	
	public func loadImage(named name: String) -> UIImage?
	{
		if let cachedImage = cachedImage(named: name) {
			return cachedImage
		} else
		if let savedImage = savedImage(atPath: cachePath(forName: name)) {
			cache(image: savedImage, named: name)
			return savedImage
		} else {
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
		let file = open(path, O_RDONLY)
		defer {
			close(file)
		}
		
		if file < 0 {
			return nil
		}
		
		//get file size
		var fileStat = stat()
		fstat(file, &fileStat);
		let fileSize = Int(fileStat.st_size)
		
		//map file
		let fileData = mmap(nil, fileSize, PROT_READ, MAP_FILE | MAP_PRIVATE, file, 0)
		if fileData == nil || fileData == MAP_FAILED {
			print("Could not mmap file to read \(path)")
			return nil
		}
		
		//first two ints are dimensions
		let width: UInt32 = fileData!.load(fromByteOffset: 0, as: UInt32.self)
		let height: UInt32 = fileData!.load(fromByteOffset: 4, as: UInt32.self)
		
		//the rest is pixel data
		let pixelData = fileData!.advanced(by: 8)
		
		let length = Int(width * height * 4)
		
		guard length > 0 else {
			print("Zero dimensions of image at \(path)")
			return nil
		}

		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
		let bitsPerComponent = 8
		let bytesPerPixel = 4
		let bitsPerPixel = bytesPerPixel * 8
		let bytesPerRow = Int(width) * bytesPerPixel
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		
		guard let dataProvider = CGDataProvider(
				dataInfo: nil,
				data: pixelData, size: length, releaseData: { info, data, size in
			//data is released automatically
		}) else
		{
			print("Unable to create data provider for \(path)")
			return nil
		}
		
		guard let cgImage = CGImage(
				width: Int(width),
				height: Int(height),
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
			let file = open(path, O_RDWR | O_CREAT | O_TRUNC, mode_t(0o600))
			defer {
				close(file)
			}
			
			var width = UInt32(image.cgImage!.width)
			var height = UInt32(image.cgImage!.height)
			let length = Int(width) * Int(height) * 4

			write(file, &width, 4)
			write(file, &height, 4)
			write(file, image.pixelData(), length)
		}
	}
	
	public static var cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].path
	
	private func cachePath(forName name: String) -> String
	{
		return "\(FastImageLoader.cachePath)/cached_image_\(name).raw"
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
