import Foundation


public struct RangeParserError: Error {

  public let expression: String
  public let type: ParseError

}

public struct RangeSegmentParserError: Error {

  public var segment: String
  public let type: ParseError

}

public struct InvalidDateFormatError: Error {
  
  public var dateString: String
  
}


public enum ParseError: Error {
  case incomplete
  case arithmeticFailure
  case invalidTimeAddition
  case roundingToUnitFailure
}

public enum Directionality {
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

public enum Unit: String, CaseIterable {
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

  private func date(byApplying tokens: [Token], to date: Date, direction: Directionality) throws -> Date {
    var date = date
    var direction = direction
    for token in tokens {
      switch token {
      case .date(let override):
        date = override
      case .boundary(let unit):
        date = try self.date(atBoundry: unit, of: date, direction: direction)
      case .skip(let segment):
        date = try self.date(byApplying: segment, to: date, direction: direction)
      case .sign(let sign):
        direction = sign
      case .error(let error):
        throw error
      }
    }
    return date
  }

  public func date(byApplying expression: String, to date: Date, direction: Directionality) throws -> Date {
    let result = try expressionParser.parse(expression)
    return try self.date(byApplying: result, to: date, direction: direction)
  }
  
  public func date(atBoundry unit: Unit, of date: Date, direction: Directionality) throws -> Date {
    try unit.boundary(of: date, direction: direction, calendar: self)
  }
    
  func date(byApplying skip: SkipSegment, to date: Date, direction: Directionality) throws -> Date {
    let result = try self.date(byAdding: skip.unit, value: skip.magnitude * direction.factor, to: date)
    return try skip.operation.apply(for: skip.unit, to: result, calendar: self)
  }

  public func range(from expression: String, referenceTime: Date = Date()) throws -> (Date, Date) {
    let definition = try rangeParser.parse(expression.filter { !$0.isWhitespace })
    let firstDate = try date(byApplying: definition.first, to: referenceTime, direction: .past)
    guard let second = definition.second else {
      return (firstDate, referenceTime)
    }
    let secondDate = try date(byApplying: second, to: firstDate, direction: .future)
    return (firstDate, secondDate)
  }
  
  public func dateInterval(from expression: String, referenceTime: Date = Date()) throws -> DateInterval {
    let pair = try range(from: expression, referenceTime: referenceTime)
    return DateInterval(start: min(pair.0,pair.1), end: max(pair.0,pair.1))
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

extension Unit {
  
  func boundary(of date: Date, direction: Directionality, calendar: TimeTraverser) throws -> Date {
    let start = try calendar.startOf(self, for: date)
    if direction == .future {
      return try calendar.date(byAdding: self, value: 1, to: start)
    } else {
      return start
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

public protocol TimeTraverser {

  func date(byAdding unit: Unit, value: Int, to date: Date) throws -> Date
  func startOf(_ unit: Unit, for date: Date) throws -> Date

}

extension Calendar: TimeTraverser {

  public func date(byAdding unit: Unit, value: Int, to date: Date) throws -> Date {
    guard let result = self.date(byAdding: unit.component, value: value, to: date)
    else { throw ParseError.invalidTimeAddition }
    return result
  }

  public func startOf(_ unit: Unit, for date: Date) throws -> Date {
    let components = dateComponents([unit.component], from: date)
    let startingDate = try self.date(byAdding: unit, value: -1, to: date)
    guard let result = nextDate(after: startingDate, matching: components, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)
    else {
      throw ParseError.roundingToUnitFailure
    }
    return result
  }

}


public extension DateFormatter {
  
  class func date(from string: String) throws -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
    dateFormatter.timeZone = .autoupdatingCurrent
        
    var segments = ["yyyy","-MM","-dd"," HH",":mm",":ss"]
    let suffixes = [
      "ZZZZZ",
      "",
    ]
    
    repeat {
      for suffix in suffixes {
        dateFormatter.dateFormat = segments.joined() + suffix
        if let result = dateFormatter.date(from: string) {
          return result
        }
      }
      segments.removeLast()
    } while !segments.isEmpty

    throw InvalidDateFormatError(dateString: string)
  }
  
}
