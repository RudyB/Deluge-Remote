//
//  BaseDestination.swift
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

/// Generic Log Output Destination Model
open class BaseDestination: Hashable {
	
	/// Denotes the format of the log
	public enum OutputFormat {
		
		/// Log in JSON format
		case json
		
		/// Log in plaintext format
		case plaintext
	}
	
	// MARK: - Output Format Configuration
	
	/// Show the date and time in the log output
	public var showDateTime = true
	
	/// Configure the DateFormat
	public var dateFormat = "HH:mm:ss.SSS"
	
	/// Configure the timezone for the DateFormat
	public var timeZone: TimeZone? = TimeZone(abbreviation: "UTC")

	/// Displays the textual representation of the log level in the log output
	///
	/// Ex. `Warning`
	public var showLogLevel = true
	
	/// Displays the Log Level Emoji Indicator in the log output
	///
	/// Ex. ⚠️
	public var showLogLevelEmoji = true
	
	/// Display the file name in the log output
	public var showFileName = true
	
	/// Display the line number in the log output
	public var showLineNumber = true
	
	/// Display the function name in the log output
	public var showFunctionName = true
	
	/// Denotes the minimum logging level
	public var minLevel = LogLevel.defaultLevel
	
	/// Executes logger on `Juliet` serial background thread for better performance
	open var asynchronously = true
	
	/// The queue of the Output Destination
	var queue: DispatchQueue?
	
	/// The output logger format
	public var outputFormat = OutputFormat.plaintext
	
	// MARK: - Base Methods
	
	/// Default Initializer. Creates new `DispatchQueue`
	public init() {
		let uuid = NSUUID().uuidString
		let queueLabel = "Houston-queue-" + uuid
		queue = DispatchQueue(label: queueLabel, target: queue)
	}
	
	/// Accepts a log and formats the log data points
	internal func acceptLog(_ level: LogLevel, function: String, file: String, line: Int, message: String) -> String? {
		switch outputFormat {
		case .plaintext:
			return formatLogOutput(level, function: function, file: file, line: line, message: message)
		case .json:
			return formatLogForJSON(level, function: function, file: file, line: line, message: message)
		}
		
	}
	
	
	
	// MARK: - Formatting
	
	/// Formatter for date and text formatting
	let formatter = DateFormatter()
	
	/// Formats the log output with the user configurable settings in `Output Format Configuration` section
	func formatLogOutput(_ level: LogLevel, function: String, file: String, line: Int, message: String) -> String {

		var fileName = ""
		if showFileName {
			fileName = fileNameOfFileWithoutFileType(file)
			if showFunctionName {
				fileName += "."
			} else {
				if showLineNumber {
					fileName += ""
				} else {
					fileName += " "
				}
			}
		}
		
		let dateComponent = showDateTime ? "[\(formatDate(dateFormat))] " : ""
		let functionName = showFunctionName ? function : ""
		let lineNumber = showLineNumber ? ":\(line) " : ""
		let emoji = showLogLevelEmoji ? "\(level.emoji) " : ""
		let levelDescription = showLogLevel ? level.description : ""

		return "\(dateComponent)\(fileName)\(functionName)\(lineNumber)\(emoji)\(levelDescription): \(message)"
		
	}
	/// Formats the log output with the user configurable settings in `Output Format Configuration` section for JSON
	func formatLogForJSON(_ level: LogLevel, function: String, file: String, line: Int, message: String) -> String? {
		var dict: [String: Any] = [
			"message": message
		]
		
		if showDateTime {
			dict["timestamp"] = Date().timeIntervalSince1970
		}
		if showFileName {
			dict["file"] = fileNameOfFileWithoutFileType(file)
		}
		if showFunctionName {
			dict["function"] = function
		}
		if showLineNumber {
			dict["line"] = line
		}
		if showLogLevelEmoji {
			dict["emoji"] = level.emoji
		}
		if showLogLevel {
			dict["level"] = level.description
		}
		return jsonStringFromDict(dict)
	}
	
	/// turns dict into JSON-encoded string
	func jsonStringFromDict(_ dict: [String: Any]) -> String? {
		var jsonString: String?
		
		// try to create JSON string
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
			jsonString = String(data: jsonData, encoding: .utf8)
		} catch {
			print("Unable to create JSON from dict")
		}
		return jsonString
	}
	
	/// Format Date with user defined `dateFormat`
	func formatDate(_ dateFormat: String) -> String {
		formatter.timeZone = timeZone
		formatter.dateFormat = dateFormat
		let dateStr = formatter.string(from: Date())
		return dateStr
	}
	
	
	/// Return the filename of a path
	private func fileNameOfFile(_ file: String) -> String {
		let fileParts = file.components(separatedBy: "/")
		if let lastPart = fileParts.last {
			return lastPart
		}
		return ""
	}
	
	/// Returns the filename of a path without the file type ending
	func fileNameOfFileWithoutFileType(_ file: String) -> String {
		let fileParts = fileNameOfFile(file).components(separatedBy: ".")
		if let firstPart = fileParts.first {
			return firstPart
		}
		return ""
	}
	
	// MARK: - Helpers
	
	/// Returns whether the outputter should accept a log statement
	func shouldLevelBeLogged(_ level: LogLevel) -> Bool {
		if level.rawValue >= minLevel.rawValue {
			return true
		} else {
			return false
		}
	}
	
	// MARK: - Hashable and Equitable
	/// Hash value used for Hashable protocol
	lazy public var hashValue: Int = self.defaultHashValue
	/// Hash value used for Hashable protocol
	open var defaultHashValue: Int {return 0}
	
	/// Used for Equitable protocol
	public static func ==(lhs: BaseDestination, rhs: BaseDestination) -> Bool {
		return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
	}
	
	
}
