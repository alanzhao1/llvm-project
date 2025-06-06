// RUN: %clang_cc1 -fsyntax-only -verify %s

struct A {};

void f() {
    bool a;

    a = __has_nothrow_assign(A);  // expected-warning-re {{__has_nothrow_assign {{.*}} use __is_nothrow_assignable}}
    a = __has_nothrow_move_assign(A);  // expected-warning-re {{__has_nothrow_move_assign {{.*}} use __is_nothrow_assignable}}
    a = __has_nothrow_copy(A);  // expected-warning-re {{__has_nothrow_copy {{.*}} use __is_nothrow_constructible}}
    a = __has_nothrow_constructor(A);  // expected-warning-re {{__has_nothrow_constructor {{.*}} use __is_nothrow_constructible}}
    a = __has_trivial_assign(A);  // expected-warning-re {{__has_trivial_assign {{.*}} use __is_trivially_assignable}}
    a = __has_trivial_move_assign(A);  // expected-warning-re {{__has_trivial_move_assign {{.*}} use __is_trivially_assignable}}
    a = __has_trivial_copy(A);  // expected-warning-re {{__has_trivial_copy {{.*}} use __is_trivially_copyable}}
    a = __has_trivial_constructor(A);  // expected-warning-re {{__has_trivial_constructor {{.*}} use __is_trivially_constructible}}
    a = __has_trivial_move_constructor(A);  // expected-warning-re {{__has_trivial_move_constructor {{.*}} use __is_trivially_constructible}}
    a = __has_trivial_destructor(A);  // expected-warning-re {{__has_trivial_destructor {{.*}} use __is_trivially_destructible}}
    a = __reference_binds_to_temporary(const A&, A); // expected-warning-re {{__reference_binds_to_temporary {{.*}} use __reference_constructs_from_temporary}}

}

void test_builtin_empty_parentheses_diags(void) {
    __has_nothrow_copy(); // expected-error {{expected a type}}
    __has_nothrow_copy(1); // expected-error {{expected a type}}
}
