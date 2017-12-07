[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/FastImageLoader.svg)](https://cocoapods.org/pods/FastImageLoader) [![Build Status](http://img.shields.io/travis/Pash237/FastImageLoader/master.svg?style=flat)](https://travis-ci.org/Pash237/FastImageLoader)

# FastImageLoader
Library to speed up subsequent `UIImage` loading (in the cost of disk space).  
It saves decoded image after first loading and then loads it fast.  
To improve performance images are stored in native pixel format and `mmap()` is used to avoid memory copy.

It is a simple library. If you need something more fundamental, please try [FastImageCache](https://github.com/mallorypaine/FastImageCache) library.

## Features

* 10x to 50x speed improvement, compared to `UIImage(named:)`
* Simple API
* Written in Swift

## Requirements

* Swift 3.0+
* iOS 8.0+

## Usage

```swift
imageView.image = FastImageLoader.shared.loadImage(named: "LovelyImage")
```

## Installation

#### CocoaPods

If you're using CocoaPods, just add this line to your Podfile:

```ruby
pod 'FastImageLoader'
```

Install by running this command in your terminal:

```sh
pod install
```

Then import the library in all files where you use it:

```swift
import FastImageLoader
```

## License

FastImageLoader is available under the MIT license. See the LICENSE file for more info.

## Author

[Pavel Alexeev](http://00b.in)
