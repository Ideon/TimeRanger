import Parsing

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

enum Token {
  case skip(SkipSegment)
  case sign(Directionality)
}

let sign = OneOf {
  "+".map { Directionality.future }
  "-".map { Directionality.past }
}.map { Token.sign($0) }

let expressionParser = Many {
  OneOf {
    sign
    segment
  }
}

let rangeParser = Parse(
  RangeDefinition.init(first:second:)
) {
  expressionParser
  Optionally {
    "~"
    expressionParser
  }
}

struct RangeDefinition {
  var first: [Token]
  var second: [Token]?
}
