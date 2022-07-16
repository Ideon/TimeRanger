import XCTest
@testable import Ranger

final class RangerTests: XCTestCase {

  func testDateRange() throws {
    XCTAssertThrowsError(try dateRange(from: ""), "Empty input is invalid and should throw a RangeParserError")
  }


  func testParseSegmentRelativeToNow() throws {
    XCTAssertThrowsError(try parseRange(segment: "", relativeTo: Date(), direction: .future), "Empty input is invalid and should throw a RangeParserError")

    let referenceDate = Date()

    let additionTests: [(String, Date, Directionality)] = [
      ("d", referenceDate.adding(0, .day), .future),
      ("5d", referenceDate.adding(5, .day), .future),
      ("41034h", referenceDate.adding(41034, .hour), .future),
      ("5d<", Calendar.current.startOfDay(for: referenceDate.adding(5, .day)), .future),
      ("5d>", Calendar.current.startOfDay(for: referenceDate.adding(6, .day)), .future),
      ("d>", Calendar.current.startOfDay(for: referenceDate.adding(1, .day)), .future),
      ("d<", Calendar.current.startOfDay(for: referenceDate.adding(0, .day)), .future),
      ("5d", referenceDate.adding(-5, .day), .past),
      ("41034h", referenceDate.adding(-41034, .hour), .past),
    ]

    for (segment, expected, direction) in additionTests {
      let result = try parseRange(segment: segment, relativeTo: referenceDate, direction: direction)
      XCTAssertEqual(result, expected, "Parsing segment '\(segment)' did not yield expected result")
    }
  }

  func testParseSegment() throws {

    let both = [Directionality.past, Directionality.future]
    let past = [Directionality.past]
    let future = [Directionality.future]

    let referenceDate = "2010-04-15 12:35:17".dateValue! // A Thursday

    let battery: [(String, String, [Directionality])] = [
      ("d<", "2010-04-15 00:00:00", both),
      ("d>", "2010-04-16 00:00:00", both),
      ("h>", "2010-04-15 13:00:00", both),
      ("h<", "2010-04-15 12:00:00", both),
      ("m>", "2010-04-15 12:36:00", both),
      ("m<", "2010-04-15 12:35:00", both),

      ("1h<", "2010-04-15 13:00:00", future),
      ("1h<", "2010-04-15 11:00:00", past),

      ("1m", "2010-04-15 12:36:17", future),
      ("52m", "2010-04-15 13:27:17", future),
      ("52m<", "2010-04-15 13:27:00", future),

      ("1s", "2010-04-15 12:35:16", past),
      ("17s", "2010-04-15 12:35:00", past),
      ("18s", "2010-04-15 12:34:59", past),
      ("1s", "2010-04-15 12:35:18", future),
      ("55s", "2010-04-15 12:36:12", future),

      ("1w", "2010-04-08 12:35:17", past),
      ("1w", "2010-04-22 12:35:17", future),

      ("w<", "2010-04-12 00:00:00", both),
      ("w>", "2010-04-19 00:00:00", both),

      ("y<", "2010-01-01 00:00:00", both),
      ("y>", "2011-01-01 00:00:00", both),

      ("L<", "2010-04-01 00:00:00", both),
      ("L>", "2010-05-01 00:00:00", both),

      ("4L", "2010-08-15 12:35:17", future),
      ("4L", "2009-12-15 12:35:17", past)

    ]

    /*
    "4w<+2h3m" 2hours 3minutes after start of the week 4 weeks ago
    "4w<2h3m" 2hours 3minutes before start of the week 4 weeks ago

    "d< ~ 5m" Range from start of today to five minutes after midnight
    "d< & 5m" Range from start of today to five minutes before midnight


     */
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    for (segment, expected, directions) in battery {
      for direction in directions {
        let result = try? parseRange(segment: segment, relativeTo: referenceDate, direction: direction, calendar: calendar)
        XCTAssertEqual(result, expected.dateValue!, "Parsing segment '\(segment)' \(direction) did not yield expected result")
      }
    }
  }


}

extension Date {

  func adding(_ value: Int, _ component: Calendar.Component) -> Date {
    Calendar.current.date(byAdding: component, value: value, to: self)!
  }

}

private extension String {

  var dateValue: Date? {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      return dateFormatter.date(from: self)
   }

}
