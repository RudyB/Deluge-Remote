<p align="center">
  <img src="https://imgur.com/RBbeVa2.png"/>
</p>

[![Build Status](https://travis-ci.org/RudyB/Houston.svg?branch=master)](https://travis-ci.org/RudyB/Houston)
[![Coverage Status](https://coveralls.io/repos/github/RudyB/Houston/badge.svg?branch=master)](https://coveralls.io/github/RudyB/Houston?branch=master)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Houston.svg)](https://cocoapods.org/pods/Houston)
[![CocoaPods](https://img.shields.io/cocoapods/dt/Houston.svg)](https://cocoapods.org/pods/Houston)
[![CocoaPods](https://img.shields.io/cocoapods/at/Houston.svg)](https://cocoapods.org/pods/Houston)
[![Platforms](https://img.shields.io/cocoapods/p/Houston.svg?style=flat)](https://cocoapods.org/pods/Houston)
[![Swift](http://img.shields.io/badge/swift-4.0-brightgreen.svg)](https://cocoapods.org/pods/Houston)
[![License](https://img.shields.io/cocoapods/l/Houston.svg?style=flat)](#license)




Houston is a simple, lightweight logging library for iOS. It is meant to allow easy logging of application data to multiple endpoints (console, stdout, http, etc).
Inspired by [corey-rb](https://github.com/corey-rb)

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Output](#output)
- [Contribute](#contribute)
- [License](#license)



## Features
- [x] Single Setup
- [x] Log Strings & Objects
- [x] Multiple Output Destinations
- [x] Formatting Customization
- [x] iOS, watchOS, tvOS, macOS compatibility
- [x] Log to File
- [ ] Log to HTTP endpoint
- [ ] [Complete Documentation](http://cocoadocs.org/docsets/Houston)


## Requirements
* Xcode 8.3+
* iOS 8.0+
* watchOS 2.0+
* macOS 10.10+
* Swift 4.0+


## Installation

To integrate Houston into your project, add the following to your project's Podfile

`pod 'Houston'`

### Carthage
Coming Soon.

### Swift Package Manager
Coming Soon.

<a name="usage"></a>
## Basic Usage (Quick Start)

In each source file,
```swift
import Houston
```

In your AppDelegate (or other global file), configure log destinations
```swift
let consoleDestination = ConsoleDestination()
Logger.add(destination: consoleDestination)
```

### Basic Logging
You can log just about anything.

You can log simple strings:

```swift
Logger.verbose("View Loaded")
Logger.warning("Yikes something is not right")
Logger.error("Fatal Error")
```

Or you can log objects:
```swift
Logger.info(Date())
Logger.debug(["Yellow", "Blue", 3])
```

## Output
<img src="https://imgur.com/0orGsD3.png" width="600px"/>

## Contribute
Want to learn Swift and help contribute? [Read Here](https://github.com/RudyB/Houston/blob/master/CONTRIBUTING.md)

## License
Houston is released under the MIT license. [See LICENSE](https://github.com/RudyB/Houston/blob/master/LICENSE) for details.
