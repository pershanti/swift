// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -typecheck -enable-library-evolution -target %target-cpu-apple-macosx12.0 -emit-module-interface-path %t/Library.swiftinterface -module-name Library %s

// REQUIRES: concurrency
// REQUIRES: OS=macosx

@available(macOS 11.0, *)
@_nonSendable
public struct X { }

@_nonSendable
public struct Y { }

// RUN: %FileCheck %s <%t/Library.swiftinterface
// CHECK: @available(macOS 11.0, *)
// CHECK-NEXT: public struct X

// CHECK: @available(macOS, unavailable, introduced: 11.0)
// CHECK-NEXT: @available(*, unavailable)
// CHECK-NEXT: extension Library.X{{( )?}}: @unchecked Swift.Sendable {

// CHECK: @available(*, unavailable)
// CHECK-NEXT: extension Library.Y{{( )?}}: @unchecked Swift.Sendable {

// RUN: %target-swift-frontend -typecheck -enable-library-evolution -target %target-cpu-apple-macosx12.0 -emit-module-interface-path %t/Library.swiftinterface -DLIBRARY -module-name Library %s -module-interface-preserve-types-as-written
// RUN: %FileCheck %s <%t/Library.swiftinterface
