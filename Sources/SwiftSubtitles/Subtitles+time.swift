//
//  Copyright © 2025 Darren Ford. All rights reserved.
//
//  MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

public extension Subtitles {
	/// A time definition for a subtitles file
	struct Time: Hashable, Comparable, Codable, Equatable, CustomDebugStringConvertible {
		/// Create a Time
		///
		/// A component past its range carries into the next unit: `second: 60` is one more
		/// minute, `millisecond: 1500` is one more second and 500 ms. Caption generators do
		/// write "01:29:60,000", and one rounding slip must not take the whole file down.
		public init(hour: UInt = 0, minute: UInt = 0, second: UInt = 0, millisecond: UInt = 0) {
			let totalMilliseconds = ((hour * 60 + minute) * 60 + second) * 1000 + millisecond
			self.hour = totalMilliseconds / 3_600_000
			self.minute = (totalMilliseconds / 60_000) % 60
			self.second = (totalMilliseconds / 1000) % 60
			self.millisecond = totalMilliseconds % 1000

			var results: Double = Double(self.hour) * 3600
			results += Double(self.minute) * 60
			results += Double(self.second)
			results += Double(self.millisecond) * 0.001
			self.timeInSeconds = results
		}

		/// Create a time from a raw seconds value. A negative value clamps to zero.
		public init(timeInSeconds seconds: Double) {
			let seconds = max(0, seconds)
			self.timeInSeconds = seconds
			let time = UInt(seconds)
			self.millisecond = UInt((seconds.truncatingRemainder(dividingBy: 1)) * 1000)
			self.second = time % 60
			self.minute = (time / 60) % 60
			self.hour = (time / 3600)
		}

		/// Simple text representation
		public var debugDescription: String { "Time: \(self.text)" }

		/// Simple time text representation
		public var text: String {
			String(format: "%02d:%02d:%02d.%03d", hour, minute, second, millisecond)
		}

		/// The hour
		public let hour: UInt
		/// The minute
		public let minute: UInt
		/// The second
		public let second: UInt
		/// The millisecond
		public let millisecond: UInt
		/// The total time in seconds
		public let timeInSeconds: Double
	}
}

// MARK: - Utilities

public extension Subtitles.Time {
	/// Returns true if the left time value is less than the right
	static func < (lhs: Subtitles.Time, rhs: Subtitles.Time) -> Bool {
		lhs.timeInSeconds < rhs.timeInSeconds
	}

	/// Returns true if lhs and rhs are equal within a 1ms difference
	static func == (lhs: Subtitles.Time, rhs: Subtitles.Time) -> Bool {
		UInt(lhs.timeInSeconds * 1000) == UInt(rhs.timeInSeconds * 1000)
	}
}

// MARK: - Time shifting

public extension Subtitles.Time {
	/// Timeshift the time
	/// - Parameter durationInSeconds: The number of seconds to shift the time
	/// - Returns: A new time
	///
	/// Clamps to 0 if the resulting time becomes negative
	func timeshifting(by durationInSeconds: Double) -> Subtitles.Time {
		Subtitles.Time(timeInSeconds: max(0, self.timeInSeconds + durationInSeconds))
	}

	/// Add a time in seconds to this time
	///
	/// Clamps to 0 if the resulting time becomes negative
	static func +(_ left: Subtitles.Time, _ right: Double) -> Subtitles.Time {
		left.timeshifting(by: right)
	}

	/// Subtract a seconds value from this time
	///
	/// Clamps to 0 if the resulting time becomes negative
	static func -(_ left: Subtitles.Time, _ right: Double) -> Subtitles.Time {
		left.timeshifting(by: -right)
	}
}

// MARK: - CMTime helpers

#if canImport(CoreMedia)

import CoreMedia

public extension Subtitles.Time {
	/// Create a time value from a CMTime (millisecond accuracy)
	init(time: CMTime) {
		self.init(timeInSeconds: CMTimeGetSeconds(time))
	}

	/// This time as a CMTime.
	var cmTime: CMTime { CMTime(seconds: self.timeInSeconds, preferredTimescale: 1000) }
}

#endif
