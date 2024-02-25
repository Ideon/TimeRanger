import Parsing
import Foundation

let unit = OneOf {
  for item in Unit.allCases {
    item.rawValue.map { item }
  }
}

let operation = OneOf {
  for item in Operation.allCases where item != .none {
    (item.rawValue).map { item }
  }
}

let segment = Parse(input: Substring.self, SkipSegment.init(magnitude:unit:operation:)) {
  Optionally { Digits() }.map { $0 ?? 0 }
  unit
  operation.replaceError(with: .none)
}.map { Token.skip($0) }

let segmentReset = Parse(input: Substring.self) {
  unit
  Not { operation }
}.map { Token.boundary($0) }

let dateFormat = Parse(input: Substring.self) {
  "@"
  PrefixUpTo("@").map {
    do {
      return try Token.date(DateFormatter.date(from: String($0)))
    } catch {
      return Token.error(error)
    }
  }
  "@"
}

enum Token {
  case boundary(Unit)
  case skip(SkipSegment)
  case sign(Directionality)
  case date(Date)
  case error(Error)
}

let sign = OneOf {
  "+".map { Directionality.future }
  "-".map { Directionality.past }
}.map { Token.sign($0) }

let expressionParser = Many {
  OneOf {
    dateFormat
    sign
    segmentReset
    segment    
  }
}

let rangeParser = Parse(
  RangeDefinition.init(first:second:)
) {
  expressionParser
  Optionally {
    OneOf { "~";"^" }
    expressionParser
  }
}

struct RangeDefinition {
  var first: [Token]
  var second: [Token]?
}
