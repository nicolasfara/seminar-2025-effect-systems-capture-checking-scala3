# Capture Checking and Separation Checking in Scala 3

---

## Slide 1: Introduction to Capture Checking

**What is Capture Checking?**
- An experimental research project modifying Scala's type system
- Tracks references to capabilities in values
- Enables the type system to reason about effects and resource lifetimes
- Currently highly experimental and evolving quickly

**Enabling the Feature:**
```scala
import language.experimental.captureChecking
```

---

## Slide 2: The Motivating Problem

**Classic Try-With-Resources Pattern:**
```scala
def usingLogFile[T](op: FileOutputStream => T): T =
  val logFile = FileOutputStream("log")
  val result = op(logFile)
  logFile.close()
  result
```

**The Problem:**
```scala
val later = usingLogFile { file => () => file.write(0) }
later() // crash - file is already closed!
```

The operation can capture the file and use it after it's closed.

---

## Slide 3: The Solution with Capture Checking

**Annotated Version:**
```scala
def usingLogFile[T](op: FileOutputStream^ => T): T =
  // same body as before
```

**Error Caught at Compile Time:**
```
val later = usingLogFile { f => () => f.write(0) }
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The expression's type () => Unit is not allowed to capture 
the root capability `cap`.
This usually means that a capability persists longer than 
its allowed lifetime.
```

The `^` symbol marks the parameter as a **tracked capability**.

---

## Slide 4: Capturing Types - Basic Syntax

**General Form:**
```
T^{c₁, c₂, ..., cᵢ}
```

- `T` is the base type
- `{c₁, c₂, ..., cᵢ}` is the **capture set**
- Contains references to capabilities the value can capture

**Examples:**
```scala
FileOutputStream^          // can capture anything
Logger^{fs}               // can only capture fs
LazyList[Int]^{l}         // can only capture l
```

---

## Slide 5: What is a Capability?

**Syntactically, a capability can be:**
1. A method or class parameter
2. A local variable
3. The `this` reference of an enclosing class

**Requirements:**
- The type of a capability must be a capturing type with a non-empty capture set
- Variables that are capabilities are called **tracked**

**The Universal Capability:**
- Written as `cap`
- The root capability from which all others derive
- `T^` is shorthand for `T^{cap}`

---

## Slide 6: Example - FileSystem and Logger

```scala
class FileSystem

class Logger(fs: FileSystem^):
  def log(s: String): Unit = ... // uses fs

def test(fs: FileSystem^) =
  val l: Logger^{fs} = Logger(fs)
  l.log("hello world!")
  
  val xs: LazyList[Int]^{l} =
    LazyList.from(1)
      .map { i =>
        l.log(s"computing elem # $i")
        i * i
      }
  xs
```

- `fs` is a capability
- `l` captures `fs`, so has type `Logger^{fs}`
- `xs` captures `l`, so has type `LazyList[Int]^{l}`

---

## Slide 7: Subtyping and Capture Sets

**Subtyping Rules:**
1. Pure types are subtypes of capturing types:
   - `T <: T^{c}`
2. Smaller capture sets produce subtypes:
   - `T^{c₁} <: T^{c₂}` if `{c₁} <: {c₂}`

**Subcapturing Relation:**
`{c₁} <: {c₂}` holds if `{c₂}` **accounts for** every element in `{c₁}`.

This means one of:
1. `c₁ ∈ {c₂}` (direct inclusion)
2. `c₁` refers to a class parameter and `{c₂}` contains `this`
3. `c₁`'s type has capture set `C` and `C <: {c₂}`

---

## Slide 8: Subcapturing Examples

Given:
```scala
fs: FileSystem^
ct: CanThrow[Exception]^
l : Logger^{fs}
```

Valid subcapturing relations:
```scala
{l} <: {fs} <: {cap}
{fs} <: {fs, ct} <: {cap}
{ct} <: {fs, ct} <: {cap}
```

**Key Insight:** The universal capability `{cap}` covers every other capture set.

---

## Slide 9: Function Types - Pure vs Impure

**Two Flavors of Functions:**

**Impure Functions** (can capture anything):
```scala
A => B              // equivalent to A ->{cap} B
A ?=> B             // context function, impure
```

**Pure Functions** (cannot capture):
```scala
A -> B              // pure function
A ?-> B             // pure context function
```

**Functions with Specific Captures:**
```scala
A ->{c, d} B        // can capture c and d only
A ->{fs} B          // can capture fs only
```

---

## Slide 10: Function Type Syntax

**Capture Annotations Bind Strongly:**
```scala
A -> B^{c}          // means A -> (B^{c})
```

**Shorthand Expansion:**
```scala
A ->{c, d} B        // is shorthand for
(A -> B)^{c, d}     // function type with captures
```

**Important Note:**
- Function arrows: `->` and `?->` are now soft keywords for types
- They remain available as regular identifiers for terms
- `Map("x" -> 1, "y" -> 2)` still works!

---

## Slide 11: By-Name Parameters

**Similar Distinctions Apply:**

```scala
def f(x: => Int): Int       // impure, can capture anything
def f(x: -> Int): Int       // pure, cannot capture
def f(x: ->{c} Int): Int    // can capture c only
```

**Example:**
```scala
f(if p(y) then throw Ex() else 1)  // OK with => Int
                                    // Error with -> Int
```

---

## Slide 12: Capability Classes

**Marking Classes as Capabilities:**
```scala
import caps.Capability

class FileSystem extends Capability
class Logger(using FileSystem):
  def log(s: String): Unit = ???
```

**Benefits:**
- Capture set `{cap}` is automatically implied
- No need to write `FileSystem^{cap}` explicitly
- Reduces boilerplate

**Warning if Explicit:**
```scala
class Logger(using FileSystem^{cap}):
                             ^^^^^^^^^^^^^^
redundant capture: FileSystem already accounts for cap
```

---

## Slide 13: Capture Checking of Closures

**Closures Capture Referenced Capabilities:**
```scala
def test(fs: FileSystem): String ->{fs} Unit =
  (x: String) => Logger(fs).log(x)
```

The closure references `fs`, so it has type `String ->{fs} Unit`.

**Transitive Capture:**
```scala
def test(fs: FileSystem) =
  def f() = g()
  def g() = (x: String) => Logger(fs).log(x)
  f
```

Result of `test` is still `String ->{fs} Unit` even though `f` doesn't directly reference `fs`.

---

## Slide 14: Capture Checking of Classes

**Classes Capture Parameters:**
```scala
class Logger(using fs: FileSystem):
  def log(s: String): Unit = ... summon[FileSystem] ...

def test(xfs: FileSystem): Logger^{xfs} =
  Logger(xfs)
```

The `Logger` instance retains `fs` as a field, so has capture set `{xfs}`.

---

## Slide 15: Constructor-Only Parameters

**The `@constructorOnly` Annotation:**
```scala
import annotation.constructorOnly

class NullLogger(using @constructorOnly fs: FileSystem):
  ...

def test2(using fs: FileSystem): NullLogger = 
  NullLogger()  // OK - fs not retained
```

Use when a capability is needed only during construction, not retained afterward.

---

## Slide 16: Captured References of a Class

**Three Types of Captured References:**

1. **Local capabilities:** Defined outside the class, referenced from its body
2. **Argument capabilities:** Passed as parameters to primary constructor
3. **Inherited local capabilities:** Local capabilities from superclasses

**Example:**
```scala
class Cap extends caps.Capability
def test(a: Cap, b: Cap, c: Cap) =
  class Super(y: Cap):
    def f = a                    // local capability
  class Sub(x: Cap) extends Super(x):
    def g = b                    // local capability
  Sub(c)                         // argument capability
```

Capture set: `{a, b, c}`

---

## Slide 17: Type of `this`

**Inference of `this` Type:**

The capture set of `this` is inferred based on:
1. All captured references of the class
2. Subtype of parent classes' `this`
3. All constraints where `this` is used

**Explicit Declaration:**
```scala
class C:
  self: D^{a, b} => ...
```

---

## Slide 18: Type of `this` - Error Example

```scala
class Cap extends caps.Capability
def test(c: Cap) =
  class A:
    val x: A = this
    def f = println(c)  // error
```

**Error:**
```
(c : Cap) cannot be referenced here; it is not included 
in the allowed capture set {}
```

`this` must be pure (empty capture set) because it's assigned to `val x: A`, but the class captures `c`.

---

## Slide 19: Capture Tunnelling

**Key Principle:**

References to capabilities **tunnel through** generic instantiations from creation to access.

**Example:**
```scala
def x: Int ->{ct} String
def y: Logger^{fs}
def p = Pair(x, y)
```

Result type:
```scala
def p: Pair[Int ->{ct} String, Logger^{fs}] = ...
```

The `Pair` itself appears pure! But captures reappear on access:
```scala
() => p.fst : () -> Int ->{ct} String
```

---

## Slide 20: Why Tunnelling?

**Benefits:**
- Makes capture checking concise and practical
- Generic data structures don't need capture annotations
- Captures are hidden during storage, revealed on access

**Example with Lists:**
```scala
val xs: List[FileOutputStream^] = List(file1, file2)
// List type itself is pure!
// But accessing elements reveals captures
```

---

## Slide 21: Escape Checking

**Restriction on Universal Capability:**

A capturing type that is an instance of a type variable **cannot** carry the universal capability `cap`.

**Rationale:**
- The capture set must be present in the environment when instantiated
- But `cap` is not available as a global entity
- Therefore, it would escape its scope

---

## Slide 22: Escape Checking Example

```scala
def usingLogFile[T](op: FileOutputStream^ => T): T = ...

val later = usingLogFile { f => () => f.write(0) }
```

**How the Error Occurs:**
1. `f` has type `FileOutputStream^`, making it a capability
2. `() => f.write(0)` has type `() ->{f} Unit`
3. The closure has dependent type `(f: FileOutputStream^) -> () ->{f} Unit`
4. Expected type is `FileOutputStream^ => T`
5. To match, `T` must be `() ->{cap} Unit`
6. But type variables can't capture `cap` → Error!

---

## Slide 23: Preventing Mutable Variable Exploits

**Another Escape Route - Mutable Variables:**
```scala
var loophole: () => Unit = () => ()
usingLogFile { f =>
  loophole = () => f.write(0)  // Error!
}
loophole()
```

**Prevention:**
Mutable variables cannot have universal capture sets.

---

## Slide 24: Preventing Cell-Based Exploits

```scala
class Cell[+A](x: A)
val sneaky = usingLogFile { f => Cell(() => f.write(0)) }
sneaky.x()  // Error!
```

**Error:**
```
The expression's type () => Unit is not allowed to capture 
the root capability `cap`.
```

At Cell creation, capture set is `{f}`. At use site, it becomes `{cap}` because `f` is out of scope.

---

## Slide 25: Monotonicity Property

**Object Graph Property:**

The capture set of object `x` covers the capture sets of:
- All objects reachable through `x`
- All applications of `x.f` to pure arguments

**Type System Rule:**

In a class `C` with field `f`:
- `{this}` covers `{this.f}`
- `{this}` covers the capture set of `this.f(pure args)`

---

## Slide 26: Checked Exceptions Integration

**Enabling Checked Exceptions:**
```scala
import language.experimental.saferExceptions

class LimitExceeded extends Exception
val limit = 10e+10

def f(x: Double): Double throws LimitExceeded =
  if x < limit then x * x else throw LimitExceeded()
```

**Expansion:**
```scala
def f(x: Double)(using CanThrow[LimitExceeded]): Double = ...
```

The `throws` clause expands to an implicit `CanThrow` capability parameter.

---

## Slide 27: Checked Exceptions - Missing Capability

```scala
def g(x: Double): Double =
  if x < limit then x * x else throw LimitExceeded()
```

**Error:**
```
The capability to throw exception LimitExceeded is missing.
The capability can be provided by one of the following:
 - Adding a using clause `(using CanThrow[LimitExceeded])`
 - Adding `throws LimitExceeded` clause
 - Wrapping this piece of code with a `try` block
```

---

## Slide 28: Checked Exceptions - Try Blocks

**Try Blocks Create Capabilities:**
```scala
try
  erased given ctl: CanThrow[LimitExceeded] = ...
  xs.map(f).sum
catch case ex: LimitExceeded => -1
```

The `try` creates a `CanThrow` capability for its body.

**Important:** The capability is `erased` - exists only for type checking!

---

## Slide 29: Checked Exceptions - Escape Prevention

```scala
def escaped(xs: Double*): (() => Double) throws LimitExceeded =
  try () => xs.map(f).sum
  catch case ex: LimitExceeded => () => -1
```

**Error:**
```
The expression's type () => Double is not allowed to capture 
the root capability `cap`.
```

**Integration Requirements:**
1. `CanThrow` extends `Capability` (tracked)
2. `try` result types cannot capture `cap`

---

## Slide 30: Lazy Lists Example - Part 1

**Base Trait:**
```scala
trait LzyList[+A]:
  def isEmpty: Boolean
  def head: A
  def tail: LzyList[A]^{this}
```

Note: `tail` has capture annotation indicating it may capture same references as the list itself.

**Empty Case:**
```scala
object LzyNil extends LzyList[Nothing]:
  def isEmpty = true
  def head = ???
  def tail = ???
```

---

## Slide 31: Lazy Lists Example - Part 2

**Lazy Cons:**
```scala
import scala.compiletime.uninitialized

final class LzyCons[+A](hd: A, tl: () => LzyList[A]^) 
  extends LzyList[A]:
  
  private var forced = false
  private var cache: LzyList[A]^{this} = uninitialized
  
  private def force =
    if !forced then { cache = tl(); forced = true }
    cache
  
  def isEmpty = false
  def head = hd
  def tail: LzyList[A]^{this} = force
```

The tail function result is memoized. Typing relies on monotonicity of `{this}`.

---

## Slide 32: Lazy Lists Example - Part 3

**Cons Operator:**
```scala
extension [A](x: A)
  def #:(xs1: => LzyList[A]^): LzyList[A]^{xs1} =
    LzyCons(x, () => xs1)
```

Takes impure call-by-name parameter `xs1`. Result captures that argument.

**Tabulate Function:**
```scala
def tabulate[A](n: Int)(gen: Int => A) =
  def recur(i: Int): LzyList[A]^{gen} =
    if i == n then LzyNil
    else gen(i) #: recur(i + 1)
  recur(0)
```

---

## Slide 33: Lazy Lists Example - Part 4

**Usage with Exceptions:**
```scala
class LimitExceeded extends Exception

def squares(n: Int)(using ct: CanThrow[LimitExceeded]) =
  tabulate(10): i =>
    if i > 9 then throw LimitExceeded()
    i * i
```

Inferred result type: `LzyList[Int]^{ct}`

The lazy list can throw `LimitExceeded` when elaborated by calling `tail`.

---

## Slide 34: Lazy Lists Example - Part 5

**Extension Methods:**
```scala
extension [A](xs: LzyList[A]^)
  def map[B](f: A => B): LzyList[B]^{xs, f} =
    if xs.isEmpty then LzyNil
    else f(xs.head) #: xs.tail.map(f)

  def filter(p: A => Boolean): LzyList[A]^{xs, p} =
    if xs.isEmpty then LzyNil
    else if p(xs.head) then xs.head #: xs.tail.filter(p)
    else xs.tail.filter(p)

  def concat(ys: LzyList[A]^): LzyList[A]^{xs, ys} =
    if xs.isEmpty then ys
    else xs.head #: xs.tail.concat(ys)
```

Capture sets reflect which impure functions and lists are retained.

---

## Slide 35: Effect Polymorphism

**Pure Functions Don't Appear in Capture Sets:**
```scala
val xs = squares(10)
val ys: LzyList[Int]^{xs} = xs.map(_ + 1)
```

The mapping function `_ + 1` is pure, so doesn't appear in the capture set of `ys`.

**Key Insight:**
Capture checking provides **effect polymorphism** naturally:
- Pure operations: no capture annotations needed
- Impure operations: captures tracked automatically

---

## Slide 36: Existential Capabilities

**The Universal Capability `cap` is Context-Dependent:**

```scala
() -> Iterator[T]^
```

Actually means:
```scala
() -> ∃x. Iterator[T]^{x}
```

An existential type - the capability is bound in the function result scope.

**Internal Representation:**
```scala
() -> (x: Exists) -> Iterator[T]^{x}
```

Where `Exists` is a sealed trait marking existentials (internal only).

---

## Slide 37: Existential Expansion Rules

**When Are Existentials Created?**

1. If function result contains covariant occurrences of `cap`, replace with fresh existential
2. Occurrences elsewhere are not translated (represent top-level existentials)

**Examples:**
```scala
A => B                    // expands to (A -> B)^
() -> A => B              // expands to () -> ∃c. A ->{c} B
() -> Iterator[A => B]    // expands to () -> ∃c. Iterator[A ->{c} B]
A -> B^                   // expands to A -> ∃c. B^{c}
```

---

## Slide 38: Existential Typing Rules

**Function Body Checking:**
- Covariant occurrences of `cap` in result type are bound with fresh existential

**Function Application:**
- Result type `∃ex. T` becomes `T` with `ex` replaced by `cap`

**Example:**
```scala
type Fun[T] = A -> T
() -> Fun[B^]             // expands to
() -> ∃c. Fun[B^{c}]      // which is
() -> ∃c. A -> B^{c}
```

Aliases control where existential binders appear.

---

## Slide 39: Reach Capabilities

**Problem - Storing List Elements:**
```scala
def f(ops: List[A => B])
var xs = ops
var x: ??? = xs.head
```

`ops` is pure (empty capture set), so can't be used as capability name.

**Solution - Reach Capabilities:**
```scala
def f(ops: List[A => B])
var xs = ops
var x: A ->{ops*} B = xs.head
```

`ops*` stands for "any capability reachable through `ops`"

---

## Slide 40: Reach Capabilities - Details

**Form:** `x*` where `x` is a regular capability

**Meaning:**
- Any capability appearing covariantly in `x`'s type
- Accessed through `x`

**Type Bound:**
If `x: T`, then `x*` represents capabilities covered by all capabilities appearing covariantly in `T`.

**Use Case:**
Expressing that a variable refers to operations "deep within" a data structure.

---

## Slide 41: Capability Polymorphism

**Parameterizing Over Capture Sets:**
```scala
class Source[X^]:
  private var listeners: Set[Listener^{X}] = Set.empty
  def register(x: Listener^{X}): Unit =
    listeners += x
  def allListeners: Set[Listener^{X}] = listeners
```

Type variable `X^` ranges over capture sets, not types.

**Usage:**
```scala
class Async extends caps.Capability
def listener(async: Async): Listener^{async} = ???

def test1(async1: Async, others: List[Async]) =
  val src = Source[{async1, others*}]
  src.register(listener(async1))
  others.map(listener).foreach(src.register)
```

---

## Slide 42: Capability Polymorphism - Bounds

**Default Bounds:**
Capture-set variables without bounds default to:
```scala
X^ >: {} <: {caps.cap}
```

The universe of all capture sets.

**Under the Hood:**
```scala
class Source[X >: CapSet <: CapSet^]
```

`CapSet` is a sealed trait identifying type variables representing capture sets.

---

## Slide 43: Capability Polymorphism - Example Use

**Tracking Mutable State:**
```scala
class ConcatIterator[A, C^](
  var iterators: mutable.List[IterableOnce[A]^{C}]
):
  def concat(it: IterableOnce[A]^): 
      ConcatIterator[A, {C, it}]^{this, it} =
    iterators ++= it
    this  // track contents of `it` in result
```

After `concat`, the capture set grows to include new iterator.

**Challenge:** Need to invalidate pre-existing aliases → solved by separation checking!

---

## Slide 44: Introduction to Separation Checking

**What is Separation Checking?**
- An extension of capture checking for safe concurrency
- Based on Capture Separation Calculus (System CSC)
- Statically prevents data races in parallel programs
- Tracks aliasing and controls mutable state access
- Currently in development (mentioned in Scala 3 docs)

**Key Philosophy:**
"Control-as-you-need" - aliases are allowed by default but tracked and controlled when necessary to prevent data races.

**Research Foundation:**
"Degrees of Separation" paper by Yichen Xu, Aleksander Boruch-Gruszecki, and Martin Odersky (2023)

---

## Slide 45: The Data Race Problem

**What Are Data Races?**
- Occur when two threads access same memory location
- At least one access is a write
- No synchronization between accesses
- Lead to non-deterministic behavior

**Traditional Solutions:**
- Rust: Ownership and borrowing (strict, intrusive)
- Linear types: Uniqueness requirements (restrictive)
- Message passing: Isolated thread heaps (limiting)

**Problem with Traditional Approaches:**
They invalidate common programming patterns and require paradigm shifts, deterring migration of existing codebases.

---

## Slide 46: CSC Philosophy - Non-Intrusive Alias Control

**Core Principle:**
Allow aliasing in general to permit common programming patterns, but track and control aliases when necessary to prevent data races.

**Sequential Code:**
Remains unchanged and well-typed (no data races possible).

**Parallel Code:**
Additional concise annotations ensure data race freedom.

**Key Innovation:**
Unlike Rust or linear types, CSC doesn't enforce strict anti-aliasing by default. It's flexible and compatible with established programming patterns.

---

## Slide 47: Separation Degrees

**What Are Separation Degrees?**
- Additional type-level information beyond capture sets
- Indicate which variables a function parameter is "separated from"
- Written as `sep` annotations in function signatures

**Syntax Example:**
```scala
def parupdate(
  p: Vec2, 
  sep f: (a: Int) => Int,  // f separated from...
  sep g: (a: Int) => Int   // g separated from...
): Unit
```

**Separation Check:**
When two computations run in parallel, their capture sets must be separated (no overlapping mutable state).

---

## Slide 48: Parallel Let Bindings

**Syntax:**
```scala
let x = t1 par t2  // binding and body in parallel
```

**Semantics:**
- Similar to futures
- Binding term `t1` and body term `t2` evaluated in parallel
- Body blocks when it needs the binding value
- Reduction interleaved until binding fully reduced

**Separation Requirement:**
The capture sets of `t1` and `t2` must be separated to ensure no data races.

---

## Slide 49: Example - Safe Parallel Update

**Sequential Version (Always Safe):**
```scala
case class Vec2(var x: Int, var y: Int):
  def update(f: Int => Int, g: Int => Int): Unit =
    x = f(x)
    y = g(y)

val v = Vec2(1, 2)
v.update(_ + 1, _ * 2)  // OK
```

No separation annotations needed for sequential code!

---

## Slide 50: Example - Parallel Update with CSC

**Parallel Version:**
```scala
def parupdate(
  p: Vec2,
  sep f: (a: Int) => Int,
  sep g: (a: Int) => Int
): Unit =
  let _ = p.x = f(p.x) par p.y = g(p.y)

val v = Vec2(1, 2)
parupdate(v, _ + 1, _ * 2)  // OK - f and g separated
```

**Why This Works:**
- `f` updates only `x` field
- `g` updates only `y` field  
- No overlapping mutable state
- Separation degrees ensure f and g don't alias shared state

---

## Slide 51: Example - Data Race Detection

**Problematic Code:**
```scala
class Loss:
  var invokes = 0
  def l1Loss(x: Double): Double =
    invokes += 1
    Math.abs(x)
  def l2Loss(x: Double): Double =
    invokes += 1
    x * x
  
  def parallelLoss(x: Double): Double =
    let l1 = l1Loss(x) par l1 + l2Loss(x)
```

**Error:** Both closures alias and mutate `invokes`. Separation check fails!

---

## Slide 52: Example - Refactored Solution

**Fixed Version:**
```scala
class Loss:
  var invokesL1 = 0
  var invokesL2 = 0
  def l1Loss(x: Double): Double =
    invokesL1 += 1
    Math.abs(x)
  def l2Loss(x: Double): Double =
    invokesL2 += 1
    x * x
  
  def parallelLoss(x: Double): Double =
    let l1 = l1Loss(x) par l1 + l2Loss(x)
```

**Now Type-Safe:**
Separation between `l1Loss` and `l2Loss` established from separation between `invokesL1` and `invokesL2`.

---

## Slide 53: Separation Degree Inference

**Good News:**
Users don't need to explicitly specify separation degrees!

**Before Inference (Explicit):**
```scala
def parupdate(
  p: Vec2,
  sep{g} f: (a: Int) => Int,
  sep{f} g: (a: Int) => Int
): Unit
```

**After Inference (Implicit):**
```scala
def parupdate(
  p: Vec2,
  sep f: (a: Int) => Int,
  sep g: (a: Int) => Int
): Unit
```

Compiler gathers constraints and solves them incrementally. Inference is local to each function.

---

## Slide 54: Immutable vs Mutable Aliases

**Key Distinction:**
CSC models both immutable and mutable aliases differently.

**Mutable Aliases:**
- Must be separated in concurrent contexts
- Can cause data races
- Tracked and controlled by separation checking

**Immutable Aliases:**
- Can safely coexist in parallel
- No race conditions from reading
- Do not need to be separated

**Example:**
Multiple threads can read the same immutable data simultaneously without races.

---

## Slide 55: Reader Capabilities

**Concept:**
Derive a read-only capability from a mutable variable.

**Purpose:**
- Possesses only the authority to read, not write
- Multiple readers can run in parallel safely
- Writers must be exclusive

**Pattern:**
Similar to readers-writer locks, but enforced statically by the type system.

**Benefit:**
Enables shared immutable views of mutable state without data races.

---

## Slide 56: The `Sharable` Trait

**Definition:**
```scala
trait Sharable extends Capability
```

**Purpose:**
Marker trait for capabilities that can be safely shared in concurrent contexts.

**Key Property:**
During separation checking, `Sharable` capabilities are **not taken into account** when checking separation.

**Example Subtypes:**
- `CanThrow[E]` extends `Sharable`
- Exception capabilities can be used in parallel without separation concerns

---

## Slide 57: Freshness and Separation

**Freshly Allocated Variables:**
- New mutable variables are not aliased by anything else
- Can be declared as separated from entire context
- Mirrors the fact that fresh allocations are unique

**Example:**
```scala
val a = new Ref(0)  // fresh, separated from context
val b = new Ref(true)  // fresh, separated from a
val c = new Ref("Hello")  // fresh, separated from a and b
```

Separation degrees can be specified arbitrarily for fresh variables.

---

## Slide 58: Following Aliases

**Transitive Separation:**
Separation checking follows aliases to establish separation between variables.

**Example:**
```scala
val x = mutableState
val y = x  // y aliases x
```

If `y` is separated from `z`, then `x` is also separated from `z` (by transitivity through aliasing).

**Benefit:**
More precise than tracking each variable independently. Leverage aliasing information to establish separations.

---

## Slide 59: Confluence and Data Race Freedom

**Theoretical Foundation:**

**Type Safety:**
System CSC proven type-safe via standard progress and preservation theorems.

**Data Race Freedom:**
Proven by establishing **confluence** of reduction semantics.

**Confluence Property:**
If a well-typed CSC program can reduce in multiple ways, all reduction paths lead to the same result (deterministic).

**Implication:**
Confluence implies no data races - concurrent operations cannot interfere destructively.

---

## Slide 60: CSC vs Rust Ownership

**Rust Example (Rejected):**
```scala
case class Vec2(var x: Int, var y: Int)
def update(mut v: Vec2, f: Int => Int, g: Int => Int) =
  v.x = f(v.x)
  v.y = g(v.y)

let mut sum = 0
let v = Vec2(1, 2)
par:
  update(v, |x| {sum += x; x + 1})  // mut borrow sum
  update(v, |y| {sum += y; y * 2})  // mut borrow sum again!
```

Error: `sum` mutably borrowed by both closures.

**CSC Approach:**
Track the aliasing, allow if non-interfering fields accessed.

---

## Slide 61: Separation Checking vs Reachability Types

**Reachability Types:**
- Enforce separation between arguments and function bodies by default
- Require explicit annotations to allow aliasing
- Considerable annotations needed for established patterns

**CSC Approach:**
- Allows aliasing by default
- Tracks aliases in capturing types
- Controls aliases only when necessary
- More compatible with existing code patterns

**Trade-off:**
CSC prioritizes flexibility and ease of adoption over strictness by default.

---

## Slide 46: Capability Members

**Alternative to Type Parameters:**
```scala
class Source:
  type X^
  private var listeners: Set[Listener^{this.X}] = Set.empty
  def register(x: Listener^{this.X}): Unit = 
    listeners += x
  def allListeners: Set[Listener^{this.X}] = listeners
```

**Benefits:**
- Can refer to capability members using paths: `{this.X}`
- Can be bounded like type members

---

## Slide 47: Capability Members - Bounds

**Bounded Capability Members:**
```scala
trait Thread:
  type Cap^
  def run(block: () ->{this.Cap} -> Unit): Unit

trait GPUThread extends Thread:
  type Cap^ >: {cudaMalloc, cudaFree} <: {caps.cap}
```

Can also omit upper bound (defaults to `{caps.cap}`):
```scala
type Cap^ >: {cudaMalloc, cudaFree}
```

---

## Slide 48: Compilation Options

**Relevant Compiler Flags:**

`-Xprint:cc`
- Prints the program with inferred capturing types
- Shows what the capture checker computed

`-Ycc-debug`
- Provides detailed, implementation-oriented information
- Shows capture set variable IDs and dependencies
- Displays boxed sets explicitly
- Shows variable provenance (mapping, filtering, etc.)

**Implementation:** Currently in `cc-experiment` branch on dotty.epfl.ch

---

## Slide 49: Capture Checking Internals - Part 1

**Architecture:**
- Propagation constraint solver
- Runs as separate phase after type-checking

**Constraint Variables:**
Introduced for:
- Every part of previously inferred type
- Accessed references of every method/class/function/by-name argument
- Parameters in class constructor calls

**Constants:**
Explicitly written capture sets in source code.

---

## Slide 50: Capture Checking Internals - Part 2

**Subtyping Checks:**
- Translate to subcapturing tests: `C₁ <: C₂`
- If both constant: yes/no answer
- If `C₁` is variable: record `C₂` as superset
- If `C₂` is variable: propagate elements of `C₁` to `C₂`

**Propagation:**
When element `x` is propagated to set `C`:
- Include `x` in `C`
- Propagate to all known supersets of `C`
- If superset is constant, verify `x ∈ superset` (error if not)

---

## Slide 51: Capture Checking Internals - Part 3

**Type Maps:**
- Performed during substitution, dependent types, selections
- Track variance: covariant/contravariant/nonvariant
- Apply to capture sets as well as types

**Mapping Capture Sets:**
- Constants: map elements as regular types, approximate by variance
  - Covariant: replace with capture set
  - Contravariant: replace with empty set
  - Nonvariant: replace with range
- Variables: create linked variable with transformed elements

---

## Slide 52: Capture Checking Internals - Part 4

**Boxing and Unboxing (Tunnelling):**

**Boxing:**
- Hides a capture set during storage in generic type
- Inserted when expected type has boxed capture variable
- Stops capability propagation

**Unboxing:**
- Recovers hidden capture set on access
- Inserted when actual type has boxed variable
- Restores capability tracking

**Important:** No runtime effect - only for type checking!

---

## Slide 53: Debug Output Example

**Variable Dependencies with `-Ycc-debug`:**
```
Capture set dependencies:
{}2V ::
{}3V ::
{}4V ::
{f, xs}5V :: {f, xs}31M5V, {f, xs}32M5V
{f, xs}31M5V :: {xs, f}
{f, xs}32M5V ::
```

**Notation:**
- `33M5V`: Variable 33, Mapped from 5, which is a regular Variable
- `V`: Regular variable
- `M`: Mapped variable
- `B`: Bijective mapping
- `F`: Filtered
- `I`: Intersection
- `D`: Difference
- `R`: Refines class parameter

---

## Slide 54: Key Takeaways - Part 1

**Capture Checking Provides:**
1. **Safe Resource Management:** Prevents use-after-close bugs
2. **Checked Exceptions:** Type-safe exception tracking
3. **Effect Polymorphism:** Pure and impure code distinguished automatically
4. **Concurrency Safety:** Async/sync composition without "colored functions"

**Core Concepts:**
- Capturing types: `T^{c₁, c₂, ...}`
- Pure vs impure functions: `->` vs `=>`
- Capability tracking through type system

---

## Slide 55: Key Takeaways - Part 2

**Advanced Features:**
1. **Capture Tunnelling:** Generic types don't need annotations
2. **Escape Checking:** Prevents capability leakage
3. **Existential Capabilities:** Context-dependent `cap`
4. **Reach Capabilities:** Track deep references `x*`
5. **Capability Polymorphism:** Parameterize over capture sets

**Design Sweet Spots:**
- Strict data structures in effectful code: no annotations
- Lazy structures in pure code: no annotations
- Only complex delayed effects need explicit annotations

---

## Slide 62: Monadic Normal Form (MNF)

**Simplification for CSC:**
CSC inherits MNF from Capture Calculus where operands in applications are restricted to variables.

**Example Transformation:**
```scala
// General form
f(g(x))

// MNF form
let y = g(x) in f(y)
```

**Benefits:**
1. Simplifies formalism
2. Typing applications only involves variable renaming
3. Makes capture sets and separation degrees easier to track
4. Also used in DOT (Dependent Object Types), Scala's theoretical foundation

---

## Slide 63: Fork-Join Parallelism Model

**What CSC Models:**
Fork-join parallelism pattern common in concurrent programming.

**Pattern:**
1. **Fork:** Split computation into parallel tasks
2. **Compute:** Tasks execute concurrently
3. **Join:** Wait for all tasks to complete before continuing

**In CSC:**
```scala
let x = task1 par task2
```

Binding (`task1`) and body (`task2`) execute in parallel, join when `x` is needed in body.

---

## Slide 64: Mutable Variables in CSC

**Restrictions:**
Content of mutable variables must have a pure type (or shape type).

**Why?**
- Simplifies reasoning about mutation
- Prevents complex aliasing through variables
- Ensures mutable state is clearly identified

**View as Capabilities:**
A mutable variable can be viewed as a capability for mutably accessing itself.

**Derived Capabilities:**
Can derive reader capabilities (read-only) from mutable variables for safe concurrent reads.

---

## Slide 65: Separation Checking - Let Bindings

**Typing Rule:**
Let bindings can be either parallel or sequential.

**Sequential Let:**
```scala
let x = t1 in t2
```
No separation check needed.

**Parallel Let:**
```scala
let x = t1 par t2
```
Checks separation between `t1` and `t2`.

**Local Variable Introduction:**
Always introduced with empty separation degree, but precision maintained by following aliases.

---

## Slide 66: Well-Formedness Constraint

**Result Type Restriction:**
Result type of let binding cannot mention the locally-bound variable.

**Why?**
Prevents variable from escaping its scope.

**Similar to:**
Capture checking's avoidance - types widen to exclude local variables.

**Example:**
```scala
let x = resource in
  processWithX(x)  // OK
// Result type cannot reference x
```

---

## Slide 67: Implementation in Scala 3

**Prototype Status:**
CSC implemented as extension to Scala 3 compiler.

**Features:**
1. Parallel let bindings
2. Separation degree annotations
3. Automatic separation inference
4. Compatible with existing Scala code

**Current State:**
- Research prototype
- Active development
- Integration with capture checking
- Mentioned in official Scala 3 documentation as "in development"

---

## Slide 68: CSC and Existing Programming Patterns

**Non-Intrusive Design:**

**Pattern 1: Separate Field Updates**
```scala
val v = Vec2(1, 2)
parupdate(v, _ + 1, _ * 2)  // Updates x and y in parallel
```
Works because fields don't alias.

**Pattern 2: Immutable Sharing**
Multiple threads reading same data - no separation required.

**Pattern 3: Sequential Composition**
Existing sequential code unchanged, remains well-typed.

---

## Slide 69: Type-Checking Process

**Steps:**
1. Type the binding term
2. Extend environment with new type assumption
3. Type the continuation (body)
4. For parallel let: check separation between binding and body

**Separation Check:**
Ensures the capture sets don't overlap on mutable state.

**Error Reporting:**
Failed checks provide hints for refactoring (e.g., split mutable variables).

---

## Slide 70: Relationship to Capture Checking

**Integration:**
Separation checking builds on capture checking infrastructure.

**Layering:**
1. **Base:** Capture checking tracks what's captured
2. **Extension:** Separation checking ensures separated access in parallel contexts

**Shared Concepts:**
- Capabilities
- Capture sets
- Tracking of references
- Escape prevention

**Additional Concepts:**
- Separation degrees
- Parallel let bindings
- Immutable vs mutable alias distinction

---

## Slide 71: Use Case - Safe Resource Management

**Pattern:**
```scala
def withFile[T](path: String)(op: File^ => T): T =
  let f = openFile(path) par
    try op(f)
    finally closeFile(f)
```

**Safety Guarantee:**
File handle `f` cannot escape the `withFile` scope due to:
1. Capture checking (prevents capture in result)
2. Separation checking (ensures exclusive access in parallel contexts)

---

## Slide 72: Use Case - Parallel Data Processing

**Safe Pattern:**
```scala
def processParallel[A, B](
  data: Array[A],
  sep f: A => B,
  sep g: A => B
): (List[B], List[B]) =
  let results1 = data.map(f) par
    (results1, data.map(g))
```

If `f` and `g` don't share mutable state, both can process data in parallel safely.

---

## Slide 73: CSC vs Linear Types

**Linear Types:**
- Enforce uniqueness (at most one reference)
- Strict: prevents many common patterns
- Requires explicit transfers of ownership

**CSC:**
- Allows aliasing by default
- Flexible: tracks but doesn't prevent aliases
- Controls only when necessary for safety

**Trade-off:**
CSC more practical for existing codebases, linear types more strict but harder to adopt.

---

## Slide 74: CSC vs Message Passing

**Message Passing (e.g., Actors):**
- Isolated thread heaps
- Communication via copying/moving messages
- No shared mutable state

**CSC:**
- Allows shared mutable state
- Tracks and controls access via separation
- More fine-grained control

**Advantage:**
CSC enables patterns where shared state is beneficial for performance.

---

## Slide 75: Polymorphism Over Separation

**Support:**
CSC supports polymorphism over separation degrees.

**Benefit:**
Write generic functions that work with different separation requirements.

**Example Concept:**
```scala
def parallel[S1, S2](
  task1: () => A,
  task2: () => B
)(implicit sep: Separation[S1, S2]): (A, B)
```

Function polymorphic over what the tasks are separated from.

---

## Slide 76: Interlinked Data Structures

**Challenge:**
Structures like doubly-linked lists have internal aliasing.

**CSC Approach:**
- Track internal aliases
- Ensure external operations respect separation
- Allow complex structures while preventing races

**Comparison:**
More flexible than systems requiring strict ownership (like early Rust proposals).

---

## Slide 77: Future Directions - Mutation Tracking

**Mentioned in Scala Docs:**
"Mutation and separation tracking are currently in development."

**Likely Goals:**
1. Track when objects are mutated
2. Invalidate aliases after mutation
3. Ensure previous references can't be used after state change

**Example Use Case:**
```scala
val it = iterator.concat(newIt)
// After mutation, old aliases to iterator should be invalid
```

---

## Slide 78: Integration with Module System

**Potential:**
Separation checking could integrate with Scala's experimental modularity features.

**Benefits:**
- Module boundaries as separation boundaries
- Static guarantees about cross-module sharing
- Better encapsulation of mutable state

**Status:**
Speculative - not yet in official roadmap.

---

## Slide 79: Practical Considerations

**Performance:**
- Static checking, no runtime overhead
- Parallel execution enabled safely
- No need for runtime synchronization in proven-safe cases

**Debugging:**
- Failed separation checks provide refactoring hints
- Type errors point to aliasing issues
- Better than runtime data race detection

**Migration:**
- Sequential code unchanged
- Incremental adoption possible
- Parallel code needs annotations (but inferred!)

---

## Slide 80: Current Status and Future

**Capture Checking Status:**
- Available with `import language.experimental.captureChecking`
- Highly experimental, evolving quickly
- Requires latest Scala version

**Separation Checking Status:**
- Research prototype implemented
- Integration with Scala 3 compiler ongoing
- "Currently in development" per official docs
- Not yet available in standard Scala releases

**Future:**
- Stabilization of capture checking
- Full integration of separation checking
- Improved inference and error messages
- Broader adoption in Scala ecosystem

---

## Summary: Key Concepts Overview

**Capture Checking:**
- Tracks references to capabilities in types
- Prevents resource leaks and use-after-close bugs
- Enables checked exceptions as capabilities
- Provides effect polymorphism
- Uses capturing types `T^{c₁, c₂, ...}`

**Separation Checking:**
- Extends capture checking for concurrency
- Prevents data races statically
- Tracks aliasing, controls when necessary
- Non-intrusive "control-as-you-need" philosophy
- Enables safe parallel programming patterns

**Together:** A powerful foundation for safe, concurrent, resource-aware programming in Scala 3!