//
//  Logger.swift
//  Houston
//
//	Copyright (c) 2017 Rudy Bermudez
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// High-level class that handles logging
open class Logger {
	
	/// The `Set` of destinations to output the log
	private static var destinations = Set<BaseDestination>()
	
	/// Enables the logger
    open var enabled : Bool = true
	
	/// Add an output destination to the logger
	///
	/// - Parameter destination: The OutputDestination to add to the logger
	/// - Returns: Bool denoting success
	@discardableResult
	public class func add(destination: BaseDestination) -> Bool {
		if destinations.contains(destination) {
			return false
		} else {
			destinations.insert(destination)
			return true
		}
	}
	
	/// Remove an output destination from the logger
	///
	/// - Parameter destination: The OutputDestination to remove from the logger
	/// - Returns: Bool denoting success
	@discardableResult
	public class func remove(destination: BaseDestination) -> Bool {
		if destinations.contains(destination) {
			destinations.remove(destination)
			return true
		} else {
			return false
		}
	}
	
	/// Allow the user to remove all destinations and start over
	open class func removeAllDestinations() {
		destinations.removeAll()
	}
	
	/// Returns the amount of open destinations
	open class func countDestinations() -> Int {
		return destinations.count
	}
	
	/// Log unimportant information (Lowest Priority)
	/// - Precondition: At least 1 destination must be configured to Logger
	///
	/// - Parameters:
	///   - message: The log message to display
	///   - file: The file where log was called
	///   - function: The function where log was called
	///   - line: The line number where log was called
	public class func verbose(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
		dispatch_log(.verbose, file: file, function: function, line: line, message: message)
	}
	
	/// Log something that will help with debugging (Low Priority)
	/// - Precondition: At least 1 destination must be configured to Logger
	///
	/// - Parameters:
	///   - message: The log message to display
	///   - file: The file where log was called
	///   - function: The function where log was called
	///   - line: The line number where log was called
	public class func debug(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
		dispatch_log(.debug, file: file, function: function, line: line, message: message)
	}
	
	/// Log something that is not an issue or error (Regular Priority)
	/// - Precondition: At least 1 destination must be configured to Logger
	///
	/// - Parameters:
	///   - message: The log message to display
	///   - file: The file where log was called
	///   - function: The function where log was called
	///   - line: The line number where log was called
	public class func info(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
		dispatch_log(.info, file: file, function: function, line: line, message: message)
	}
	
	/// Log something that may lead to an error (High Priority)
	/// - Precondition: At least 1 destination must be configured to Logger
	///
	/// - Parameters:
	///   - message: The log message to display
	///   - file: The file where log was called
	///   - function: The function where log was called
	///   - line: The line number where log was called
	public class func warning(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
		dispatch_log(.warning, file: file, function: function, line: line, message: message)
	}
	
	/// Log an error. This is something that is fatal. (Highest Priority)
	/// - Precondition: At least 1 destination must be configured to Logger
	///
	/// - Parameters:
	///   - message: The log message to display
	///   - file: The file where log was called
	///   - function: The function where log was called
	///   - line: The line number where log was called
	public class func error(_ message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line) {
		dispatch_log(.error, file: file, function: function, line: line, message: message)
	}
	
	/// Dispatch log to Destination if the destination minLevel permits it
	/// - Precondition: At least 1 destination must be configured to Logger
	///
	/// - Parameters:
	///   - level: The `LogLevel` of the log
	///   - message: The log message to display
	///   - file: The file where log was called
	///   - function: The function where log was called
	///   - line: The line number where log was called
	class func dispatch_log(_ level: LogLevel, file: String = #file, function: String = #function, line: Int = #line, message: @autoclosure () -> Any) {
		
		// Iterate through all destinations
		for dest in destinations {
			
			guard let queue = dest.queue else {
				continue
			}
			
			// Check to see if destination will accept the log level
			if dest.shouldLevelBeLogged(level) {
				
				let message = "\(message())"
				
				// Check to see if the destination is configured asynchronously or synchronously
				if dest.asynchronously {
					queue.async {
						_ = dest.acceptLog(level, function: function, file: file, line: line, message: message)
					}
				} else {
					queue.sync {
						_ = dest.acceptLog(level, function: function, file: file, line: line, message: message)
					}
				}
				
			}
		}
	}
	
    
}
