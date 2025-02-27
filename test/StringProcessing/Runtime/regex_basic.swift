// RUN: %target-run-simple-swift(-Xfrontend -enable-experimental-string-processing)

// REQUIRES: swift_in_compiler,string_processing,executable_test

import StdlibUnittest

var RegexBasicTests = TestSuite("RegexBasic")

extension String {
  func expectMatch<T>(
    _ regex: Regex<T>,
    file: String = #file,
    line: UInt = #line
  ) -> Regex<T>.Match {
    guard let result = match(regex) else {
      expectUnreachable("Failed match", file: file, line: line)
      fatalError()
    }
    return result
  }
}

RegexBasicTests.test("Basic") {
  let input = "aabccd"

  let match1 = input.expectMatch(#/aabcc./#)
  expectEqual("aabccd", match1.0)
  expectTrue("aabccd" == match1.output)

  let match2 = input.expectMatch(#/a*b.+./#)
  expectEqual("aabccd", match2.0)
  expectTrue("aabccd" == match2.output)
}

RegexBasicTests.test("Modern") {
  let input = "aabccd"

  let match1 = input.expectMatch(#|a a  bc c /*hello*/ .|#)
  expectEqual("aabccd", match1.0)
  expectTrue("aabccd" == match1.output)
}

RegexBasicTests.test("Captures") {
  let input = """
    A6F0..A6F1    ; Extend # Mn   [2] BAMUM COMBINING MARK KOQNDON..BAMUM \
    COMBINING MARK TUKWENTIS
    """
  let regex = #/([0-9A-F]+)(?:\.\.([0-9A-F]+))?\s+;\s+(\w+).*/#
  // Test inferred type.
  let _: Regex<(Substring, Substring, Substring?, Substring)>.Type
    = type(of: regex)
  let match1 = input.expectMatch(regex)
  expectEqual(input[...], match1.0)
  expectTrue(input == match1.0)
  expectTrue("A6F0" == match1.1)
  expectTrue("A6F1" == match1.2)
  expectTrue("Extend" == match1.3)
}

runAllTests()
