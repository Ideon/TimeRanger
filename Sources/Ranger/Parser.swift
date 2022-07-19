import Parsing

let unit = OneOf {
  for item in Unit.allCases {
    item.rawValue.utf8.map { item }
  }
}

let operation = OneOf {
  for item in Operation.allCases where item != .none {
    (item.rawValue.utf8).map { item }
  }
}

let segment = Parse(SkipSegment.init(magnitude:unit:operation:)) {
  Optionally { Digits() }.map { $0 ?? 0 }
  unit
  operation.replaceError(with: .none)
}.map { Token.skip($0) }

enum Token {
  case skip(SkipSegment)
  case sign(Directionality)
}

let sign = OneOf {
  "+".utf8.map { Directionality.future }
  "-".utf8.map { Directionality.past }
}.map { Token.sign($0) }

let expressionParser = Many {
  OneOf {
    sign
    segment
  }
}
