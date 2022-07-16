import Foundation


public struct RangeParserError: Error {

  public let expression: String
  public let type: ParseError

}

public struct RangeSegmentParserError: Error {

  public var segment: String
  public let type: ParseError

}

public enum ParseError: Error {
  case incomplete
  case arithmeticFailure
}


public func dateRange(from expression: String) throws -> (Date, Date)? {
  throw RangeParserError(expression: expression, type: .incomplete)
}

enum Directionality {
  case past, future
}

extension Directionality {

  var factor: Int {
    self == .future ? 1 : -1
  }

}

enum Unit: String {
  case day = "d"
  case hour = "h"
  case minute = "m"
  case second = "s"
  case week = "w"
}

enum Operation: String {
  case none = ""
  case skipBack = "<"
  case skipForward = ">"
}

func parseRange(segment: String, relativeTo date: Date, direction: Directionality, calendar: Calendar = .current) throws -> Date {

  var real = ""

  var iterator = segment.makeIterator()
  var current = iterator.next()
  while let digit = current, digit.isNumber {
    real.append(digit)
    current = iterator.next()
  }
  guard case let unit?? = current.map({ Unit(rawValue: String($0)) }) else {
    throw RangeSegmentParserError(segment: segment, type: .incomplete)
  }
  let operation = iterator.next().map { Operation(rawValue: String($0)) ?? .none } ?? Operation.none
  let magnitude = Int(real) ?? 0

  guard let result = calendar.date(byAdding: unit.component, value: magnitude * direction.factor, to: date)

  else {
    throw RangeSegmentParserError(segment: segment, type: .arithmeticFailure)
  }

  do {
    return try operation.apply(for: unit, to: result, calendar: calendar)
  } catch (let error as ParseError) {
    throw RangeSegmentParserError(segment: segment, type: error)
  } catch {
    throw error
  }

}

extension Unit {

  var component: Calendar.Component {
    switch self {
    case .day: return .day
    case .hour: return .hour
    case .minute: return .minute
    case .second: return .second
    case .week: return .weekOfYear
    }
  }

}

extension Operation {

  func apply(for unit: Unit, to date: Date, calendar: Calendar) throws -> Date {
    if self == .none { return date }

//    let currentValue = calendar.component(unit.component, from: date)
    let components = calendar.dateComponents([unit.component], from: date)

    let referenceDate = calendar.date(byAdding: unit.component, value: -1, to: date)!

    guard var result = calendar.nextDate(after: referenceDate, matching: components, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)
    else {
      throw ParseError.arithmeticFailure
    }

    if self == .skipForward {
      guard let forwardedResult = calendar.date(byAdding: unit.component, value: 1, to: result) else {
        throw ParseError.arithmeticFailure
      }
      result = forwardedResult
    }

    print(components)
    if #available(macOS 12.0, *) {
      print(date.formatted(date: .abbreviated, time: .standard))
      print(result.formatted(date: .abbreviated, time: .standard))
    }
    return result
  }

}
