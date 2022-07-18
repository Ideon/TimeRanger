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
  case invalidTimeAddition
  case roundingToUnitFailure
}

enum Directionality {
  case past, future
}

extension Directionality {

  var factor: Int {
    self == .future ? 1 : -1
  }

}

enum Base: String {
  case now = "*" // or @
  case epoch = "E"
  case midnight = "D"
}

enum Unit: String, CaseIterable {
  case year = "y"
  case month = "L"
  case day = "d"
  case week = "w"
  case hour = "h"
  case minute = "m"
  case second = "s"
  case nanosecond = "n"
}

enum Operation: String, CaseIterable {
  case skipBack = "<"
  case skipForward = ">"
  case none = ""
}

struct SkipSegment {

  var magnitude: Int
  var unit: Unit
  var operation: Operation

}

extension TimeTraverser {

  public func date(byApplying expression: String, to date: Date, direction: Directionality) throws -> Date {
    var date = date
    var direction = direction
    let result = try expressionParser.parse(expression)
    for token in result {
      switch token {
      case .skip(let segment):
        date = try self.date(byApplying: segment, to: date, direction: direction)
      case .sign(let sign):
        direction = sign
      }
    }
    return date
  }

  func date(byApplying skip: SkipSegment, to date: Date, direction: Directionality) throws -> Date {
    let result = try self.date(byAdding: skip.unit, value: skip.magnitude * direction.factor, to: date)
    return try skip.operation.apply(for: skip.unit, to: result, calendar: self)
  }

  public func dateRange(from expression: String) throws -> (Date, Date) {
    let parts = expression.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
    do {

      if parts.count == 1 {
        let firstDate = try self.date(byApplying: parts[0].trimmingCharacters(in: .whitespaces), to: Date(), direction: .past)
        return (firstDate, .distantFuture)
      }

      guard parts.count > 1
      else { throw RangeParserError(expression: expression, type: .incomplete) }

      let firstExpression = parts[0].trimmingCharacters(in: .whitespaces)
      let secondExpression = parts[1].trimmingCharacters(in: .whitespaces)

      let firstDate = try self.date(byApplying: firstExpression, to: Date(), direction: .past)

      let secondDate = try self.date(byApplying: secondExpression, to: firstDate, direction: .future)
      return (firstDate, secondDate)

    } catch (let error as ParseError) {
      throw RangeParserError(expression: expression, type: error)
    } catch {
      throw error
    }
  }

  public func dateInterval(from expression: String) throws -> DateInterval {
    let pair = try dateRange(from: expression)
    return DateInterval(start: pair.0, end: pair.1)
  }

}

extension Unit {

  var component: Calendar.Component {
    switch self {
    case .year: return .year
    case .month: return .month
    case .week: return .weekOfYear
    case .day: return .day
    case .hour: return .hour
    case .minute: return .minute
    case .second: return .second
    case .nanosecond: return .nanosecond
    }
  }

}

extension Operation {

  func apply(for unit: Unit, to date: Date, calendar: TimeTraverser) throws -> Date {
    if self == .none { return date }
    let start = try calendar.startOf(unit, for: date)
    if self == .skipForward {
      return try calendar.date(byAdding: unit, value: 1, to: start)
    } else {
      return start
    }
  }

}

protocol TimeTraverser {

  func date(byAdding unit: Unit, value: Int, to date: Date) throws -> Date
  func startOf(_ unit: Unit, for date: Date) throws -> Date

}

extension Calendar: TimeTraverser {

  func date(byAdding unit: Unit, value: Int, to date: Date) throws -> Date {
    guard let result = self.date(byAdding: unit.component, value: value, to: date)
    else { throw ParseError.invalidTimeAddition }
    return result
  }

  func startOf(_ unit: Unit, for date: Date) throws -> Date {
    let components = dateComponents([unit.component], from: date)
    let startingDate = try self.date(byAdding: unit, value: -1, to: date)
    guard let result = nextDate(after: startingDate, matching: components, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)
    else {
      throw ParseError.roundingToUnitFailure
    }
    return result
  }

}
