//
//  ViewController.swift
//  FastImageLoaderExample
//
//  Created by Pavel Alexeev on 06/12/2017.
//  Copyright © 2017 Pavel Alexeev. All rights reserved.
//

import UIKit
import FastImageLoader

class ViewController: UIViewController
{
	override func viewDidLoad()
	{
		super.viewDidLoad()
		loadImages()
	}
	
	func loadImages()
	{
		let imageCount = 300
		var imageViews = Array<UIImageView>()
		
		for i in 0..<imageCount {
			let imageView = UIImageView(frame: CGRect(
				x:0,
				y: CGFloat(i) * view.frame.height/CGFloat(imageCount),
				width: view.frame.width,
				height: view.frame.height/CGFloat(imageCount)
			))
			view.addSubview(imageView)
			imageViews.append(imageView)
		}
		
		//FastImageLoader.shared.purgeCache()
		
		let start = CFAbsoluteTimeGetCurrent()
		
		for i in 0..<imageCount {
			imageViews[i].image = FastImageLoader.shared.loadImage(named: "\(i).png")
		}
		
		let time = CFAbsoluteTimeGetCurrent() - start
		print("\(imageCount) images loaded in \(round(time*1000)) ms")
	}
}

