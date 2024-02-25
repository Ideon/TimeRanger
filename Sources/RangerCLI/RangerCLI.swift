import Chalk
import ArgumentParser
import Foundation
import Ranger

@main
struct RangerCLI: AsyncParsableCommand {
  
  @OptionGroup() var timeRangeOptions: TimeRangeOptions
  
  func run() async throws {
    
    
    let input = timeRangeOptions.timeRange.joined(separator: " ")
    let interval = try timeRangeOptions.interval
    
    print("\("Input  :", color: .blue) \(input)")
    
    print("\("Output :", color: .blue) \(interval)")
    
    print("\("Start   :", color: .green) \(interval.start)")
    print("\("End     :", color: .yellow) \(interval.end)")
    print("\("Duration:", color: .magenta) \(interval.duration)")
    
    
  }
}


struct TimeRangeOptions: ParsableArguments {
  @Option(name: .shortAndLong, parsing: .upToNextOption, help: "Time range to include in the result set (special syntax TBD)") var timeRange: [String] = []
}

extension TimeRangeOptions {
  
  var interval: DateInterval {
    
    get throws {
      var interval = DateInterval(start: .distantPast, end: .distantFuture)
      if !timeRange.isEmpty {
        let expression = timeRange.joined(separator: "")
        interval = try Calendar.current.dateInterval(from: expression)
      }
      return interval
    }
  }
}
