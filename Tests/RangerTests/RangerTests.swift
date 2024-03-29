import XCTest
@testable import Ranger

final class RangerTests: XCTestCase {

  func testParseSegmentRelativeToNow() throws {
    let referenceDate = Date()

    let additionTests: [(String, Date, Directionality)] = [
      ("d", Calendar.current.startOfDay(for: referenceDate.adding(1, .day)), .future),
      ("d", Calendar.current.startOfDay(for: referenceDate), .past),
      ("L", try! Calendar.current.startOf(.month, for: referenceDate), .past),
      ("0d", referenceDate.adding(0, .day), .future),
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
      let result = try? Calendar.current.date(byApplying: segment, to: referenceDate, direction: direction)
      XCTAssertEqual(result, expected, "Parsing segment '\(segment)' did not yield expected result")
    }
  }

  func testStartOfUnit() throws {
    let referenceDate = "2010-04-15 12:35:17".dateValue // A Thursday
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let battery: [(Ranger.Unit, String)] = [
      (.day, "2010-04-15 00:00:00"),
      (.hour, "2010-04-15 12:00:00"),
      (.minute, "2010-04-15 12:35:00"),
      (.week, "2010-04-12 00:00:00"),
      (.year, "2010-01-01 00:00:00"),
      (.month, "2010-04-01 00:00:00"),
    ]

    for (unit, expected) in battery {
      let result = try? calendar.startOf(unit, for: referenceDate)
      XCTAssertEqual(result, expected.dateValue, "Start of '\(unit)' did not yield expected result")
    }
  }

  func testDateByAddingUnit() throws {
    let referenceDate = "2010-04-15 12:35:17".dateValue // A Thursday
    let calendar = Calendar.current

    let battery: [(Ranger.Unit, Int, String)] = [

      (.hour, 1, "2010-04-15 13:35:17"),
      (.minute, 1 ,"2010-04-15 12:36:17"),
      (.minute, 52, "2010-04-15 13:27:17"),

      (.second, -1, "2010-04-15 12:35:16"),
      (.second, -17, "2010-04-15 12:35:00"),
      (.second, -18, "2010-04-15 12:34:59"),
      (.second, 1, "2010-04-15 12:35:18"),
      (.second, 55,"2010-04-15 12:36:12"),

      (.week, -1, "2010-04-08 12:35:17"),
      (.week, 1, "2010-04-22 12:35:17"),
    ]

    for (unit, value, expected) in battery {
      let result = try? calendar.date(byAdding: unit, value: value, to: referenceDate)
      XCTAssertEqual(result, expected.dateValue, "Adding \(value) '\(unit)' did not yield expected result")
    }
  }

  func testParseSegment() throws {

    let both = [Directionality.past, Directionality.future]
    let past = [Directionality.past]
    let future = [Directionality.future]

    let referenceDate = "2010-04-15 12:35:17".dateValue // A Thursday

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

    var calendar = Calendar.current
    calendar.firstWeekday = 2

    for (segment, expected, directions) in battery {
      for direction in directions {
        let result = try? calendar.date(byApplying: segment, to: referenceDate, direction: direction)
        XCTAssertEqual(result, expected.dateValue, "Parsing segment '\(segment)' \(direction) did not yield expected result")
      }
    }
  }

  func testParseSignedSegment() throws {

    let referenceDate = "2010-04-15 12:35:17".dateValue // A Thursday

    let battery: [(String, String)] = [
      ("d<", "2010-04-15 00:00:00"),
      ("d>", "2010-04-16 00:00:00"),
      ("h>", "2010-04-15 13:00:00"),
      ("h<", "2010-04-15 12:00:00"),
      ("m>", "2010-04-15 12:36:00"),
      ("m<", "2010-04-15 12:35:00"),

      ("+1h<", "2010-04-15 13:00:00"),
      ("-1h<", "2010-04-15 11:00:00"),

      ("+1m", "2010-04-15 12:36:17"),
      ("+52m", "2010-04-15 13:27:17"),
      ("+52m<", "2010-04-15 13:27:00"),

      ("-1s", "2010-04-15 12:35:16"),
      ("-17s", "2010-04-15 12:35:00"),
      ("-18s", "2010-04-15 12:34:59"),
      ("+1s", "2010-04-15 12:35:18"),
      ("+55s", "2010-04-15 12:36:12"),

      ("-1w", "2010-04-08 12:35:17"),
      ("+1w", "2010-04-22 12:35:17"),

      ("w<", "2010-04-12 00:00:00"),
      ("w>", "2010-04-19 00:00:00"),

      ("y<", "2010-01-01 00:00:00"),
      ("y>", "2011-01-01 00:00:00"),

      ("L<", "2010-04-01 00:00:00"),
      ("L>", "2010-05-01 00:00:00"),

      ("4L", "2010-08-15 12:35:17"),
      ("-4L", "2009-12-15 12:35:17")

    ]

    var calendar = Calendar.current
    calendar.firstWeekday = 2

    for (segment, expected) in battery {
      let result = try? calendar.date(byApplying: segment, to: referenceDate, direction: .future)
      XCTAssertEqual(result, expected.dateValue, "Parsing segment '\(segment)' did not yield expected result")
    }
  }



  /*
  "4w<+2h3m" 2hours 3minutes after start of the week 4 weeks ago
  "4w<2h3m" 2hours 3minutes before start of the week 4 weeks ago

  "d< ~ 5m" Range from start of today to five minutes after midnight
  "d< & 5m" Range from start of today to five minutes before midnight

   */

  func testParseRange() throws {
    let referenceDate = "2010-04-15 12:35:17".dateValue // A Thursday
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let battery: [(String, String, String?)] = [
      ("2d3h", "2010-04-13 09:35:17", nil),
      ("2d-3h", "2010-04-13 09:35:17", nil),
      ("2d-3hm<", "2010-04-13 09:35:00", nil),
      ("2d+3h", "2010-04-13 15:35:17", nil),
      ("2d+3hm<", "2010-04-13 15:35:00", nil),

      ("2d+3hm< ~ 4s", "2010-04-13 15:35:00", "2010-04-13 15:35:04"),
    ]

    for (expression, first, second) in battery {
      let result = try? calendar.range(from: expression, referenceTime: referenceDate)
      XCTAssertEqual(result?.0, first.dateValue, "First result of expression '\(expression)' did not yield expected result")

      XCTAssertEqual(result?.1, second?.dateValue ?? referenceDate, "Second result of expression '\(expression)' did not yield expected result")
    }

  }

  func testParseExpression() throws {
    let referenceDate = "2010-04-15 12:35:17".dateValue // A Thursday
    var calendar = Calendar.current
    calendar.firstWeekday = 2

    let battery: [(String, String)] = [
      ("2d3h", "2010-04-17 15:35:17"),
      ("2d-3h", "2010-04-17 09:35:17"),
      ("2d-3hm<", "2010-04-17 09:35:00"),
    ]

    for (expression, expected) in battery {
      let result = try? calendar.date(byApplying: expression, to: referenceDate, direction: .future)
      XCTAssertEqual(result, expected.dateValue, "Result of expression '\(expression)' did not yield expected result")
    }
  }

}

extension Date {

  func adding(_ value: Int, _ component: Calendar.Component) -> Date {
    Calendar.current.date(byAdding: component, value: value, to: self)!
  }

}

private extension String {

  var dateValue: Date {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      return dateFormatter.date(from: self)!
   }

}
