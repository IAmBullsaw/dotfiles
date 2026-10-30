---
name: cpp-coding-standards
type: reference
description: "Reference: C++ coding standards based on the C++ Core Guidelines. Use when writing or reviewing C++ code, or choosing between language features (enum class, smart pointers, RAII)."
---

# C++ Coding Standards Reference

Adapted from Everything Claude Code `skills/cpp-coding-standards/SKILL.md`.
Based on the [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines).

## When to use

- Writing or reviewing C++ code
- Choosing between language features (enum vs enum class, raw pointer vs smart pointer)
- Quick lookup during code review

## Cross-Cutting Principles

1. **RAII everywhere** (P.8, R.1, E.6, CP.20): Bind resource lifetime to object lifetime
2. **Immutability by default** (P.10, Con.1-5, ES.25): Start with `const`/`constexpr`; mutability is the exception
3. **Type safety** (P.4, I.4, ES.46-49, Enum.3): Use the type system to prevent errors at compile time
4. **Express intent** (P.3, F.1, NL.1-2, T.10): Names, types, and concepts should communicate purpose
5. **Minimize complexity** (F.2-3, ES.5, Per.4-5): Simple code is correct code
6. **Value semantics over pointer semantics** (C.10, R.3-5, F.20, CP.31): Prefer returning by value and scoped objects

## Parameter Passing (F.16, F.20, F.21)

```cpp
void print(int x);                           // cheap: by value
void analyze(const std::string& data);       // expensive: by const&
void transform(std::string s);               // sink: by value (will move)

// Return structs, not output parameters
struct ParseResult { std::string token; int position; };
ParseResult parse(std::string_view input);   // GOOD
```

## Classes (C.20, C.21, C.35, C.46)

- **Rule of Zero:** Let compiler generate special members when possible
- **Rule of Five:** If you define any of destructor/copy/move, define all five
- **Base class destructor:** public virtual or protected non-virtual
- **Single-argument constructors:** always `explicit`
- **Virtual functions:** specify exactly one of `virtual`, `override`, or `final`

## Resource Management (R.*)

- Raw pointer (`T*`) = non-owning observer
- Prefer `unique_ptr` over `shared_ptr` unless sharing ownership
- Use `make_unique`/`make_shared`
- Never naked `new`/`delete`

## Concurrency (CP.*)

- RAII locks only: `std::lock_guard`, `std::scoped_lock`, `std::unique_lock`
- `std::scoped_lock` for multiple mutexes (deadlock-free)
- Never call unknown code while holding a lock
- Always wait with a condition (no bare `cv.wait()`)
- Name your lock guards (unnamed = immediate destruction)
- `volatile` is for hardware I/O, not synchronization

## Error Handling (E.*)

- Custom exception types inheriting from `std::runtime_error`
- Throw by value, catch by `const&`
- Destructors, deallocation, and swap must never fail
- Don't catch everything in every function

## Quick Review Checklist

- [ ] No raw `new`/`delete` (R.11)
- [ ] Objects initialized at declaration (ES.20)
- [ ] Variables `const`/`constexpr` by default (Con.1, ES.25)
- [ ] Member functions `const` where possible (Con.2)
- [ ] `enum class` not plain `enum` (Enum.3)
- [ ] `nullptr` not `0`/`NULL` (ES.47)
- [ ] No C-style casts (ES.48)
- [ ] Single-arg constructors `explicit` (C.46)
- [ ] Rule of Zero or Rule of Five (C.20, C.21)
- [ ] Locks use RAII (CP.20)
- [ ] Exceptions: custom types, throw by value, catch by ref (E.14, E.15)
- [ ] `'\n'` not `std::endl` (SL.io.50)
- [ ] No magic numbers (ES.45)
- [ ] No `using namespace` in headers (SF.7)
