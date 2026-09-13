import XCTest
@testable import SwiftSubtitles

/// Out-of-range components must carry into the next unit instead of trapping.
/// Real-world captions (Podcasting 2.0 episode 270) contain "01:29:60,000".
final class TimeTests: XCTestCase {

	func testSecondsOverflowCarriesIntoMinutes() throws {
		let t = Subtitles.Time(hour: 1, minute: 29, second: 60, millisecond: 0)
		XCTAssertEqual(t.timeInSeconds, 5400, accuracy: 0.0001)
		XCTAssertEqual(t.hour, 1)
		XCTAssertEqual(t.minute, 30)
		XCTAssertEqual(t.second, 0)
		XCTAssertEqual(t.millisecond, 0)
		XCTAssertEqual(t, Subtitles.Time(hour: 1, minute: 30))
	}

	func testMillisecondsAndMinutesOverflowCarry() throws {
		let t = Subtitles.Time(hour: 0, minute: 61, second: 59, millisecond: 1500)
		// 61 min + 59 s + 1.5 s = 1 h 2 min 0.5 s
		XCTAssertEqual(t.timeInSeconds, 3720.5, accuracy: 0.0001)
		XCTAssertEqual(t.hour, 1)
		XCTAssertEqual(t.minute, 2)
		XCTAssertEqual(t.second, 0)
		XCTAssertEqual(t.millisecond, 500)
	}

	func testInRangeComponentsAreUnchanged() throws {
		let t = Subtitles.Time(hour: 2, minute: 3, second: 4, millisecond: 5)
		XCTAssertEqual(t.hour, 2)
		XCTAssertEqual(t.minute, 3)
		XCTAssertEqual(t.second, 4)
		XCTAssertEqual(t.millisecond, 5)
		XCTAssertEqual(t.timeInSeconds, 7384.005, accuracy: 0.0001)
	}

	func testNegativeRawSecondsClampToZero() throws {
		let t = Subtitles.Time(timeInSeconds: -1.5)
		XCTAssertEqual(t.timeInSeconds, 0)
		XCTAssertEqual(t.second, 0)
		XCTAssertEqual(t.millisecond, 0)
	}

	func testSRTCueWithSixtySecondsDecodes() throws {
		let content = """
1253
01:29:60,000 --> 01:30:02,862
You can go get Audacity and you can record stuff

"""
		let srt = try Subtitles(content: content, expectedExtension: "srt")
		XCTAssertEqual(srt.cues.count, 1)
		XCTAssertEqual(srt.cues[0].startTimeInSeconds, 5400, accuracy: 0.0001)
		XCTAssertEqual(srt.cues[0].endTimeInSeconds, 5402.862, accuracy: 0.0001)
		XCTAssertEqual(srt.cues[0].startTime.text, "01:30:00.000")
	}
}
