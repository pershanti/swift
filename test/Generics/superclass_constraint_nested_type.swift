// RUN: %target-typecheck-verify-swift -requirement-machine-protocol-signatures=verify -requirement-machine-inferred-signatures=verify
// RUN: not %target-swift-frontend -typecheck %s -debug-generic-signatures -requirement-machine-protocol-signatures=verify -requirement-machine-inferred-signatures=verify 2>&1 | %FileCheck %s

// rdar://problem/39481178 - Introducing a superclass constraint does not add
// same-type constraints on nested types

protocol P {
  associatedtype Q
}

class C : P {
  typealias Q = Int
}

// Use the "generic parameter cannot be concrete" check as a proxy for the
// same-type constraint 'T == C.Q (aka Int)' having been inferred:

extension P {
  // CHECK-LABEL: .f1@
  // CHECK-NEXT: <Self, T where Self : C, T == Int>
  func f1<T>(_: T) where T == Q, Self : C {}
  // expected-error@-1 {{same-type requirement makes generic parameter 'T' non-generic}}

  // CHECK-LABEL: .f2@
  // CHECK-NEXT: <Self, T where Self : C, T == Int>
  func f2<T>(_: T) where Self : C, T == Q {}
  // expected-error@-1 {{same-type requirement makes generic parameter 'T' non-generic}}
}
