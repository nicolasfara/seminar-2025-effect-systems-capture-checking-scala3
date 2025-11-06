#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/fontawesome:0.5.0": *
#import "@preview/ctheorems:1.1.3": *
#import "@preview/numbly:0.1.0": numbly
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "utils.typ": *

#show: codly-init.with()
#codly(languages: (scala: (name: [scala])), default-color: red, display-name: false, display-icon: false)

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-common(
    // handout: true,
    show-bibliography-as-footnote: bibliography(title: none, "bibliography.bib"),
  ),
  config-info(
    title: [Effects Systems? Direct-style and Capture Checking],
    subtitle: [A practical overview in Scala 3],
    author: author_list(
      (
        (first_author("Nicolas Farabegoli"), "nicolas.farabegoli@unibo.it"),
      )
    ),
    date: datetime.today().display("[day] [month repr:long] [year]"),
    institution: [Alma Mater Studiorum -- Università di Bologna],
    // logo: align(right)[#image("images/disi.svg", width: 55%)],
  ),
)

#set text(font: "Fira Sans", weight: "light", size: 20pt)
#show math.equation: set text(size: 20pt)

// #set raw(tab-size: 4)
#show raw: set text(size: 1em)
// #show raw.where(block: true): block.with(
//   fill: luma(240),
//   inset: (x: 1em, y: 1em),
//   radius: 0.7em,
//   width: 100%,
// )

#show bibliography: set text(size: 0.75em)
#show footnote.entry: set text(size: 0.75em)

// #set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

= What we care about

== Reasoning and Composition

One of core values of #bold[functional programming] are *reasoning* and *composition*.

#warning-block("Side Effects")[
_*Side effects*_ stops us from achieving this goal.
]

But every (useful) program has to #underline[interact] with the outside world.

In #bold[functional programming], replacing _side effects_ with something that helps achieving these goals is an #underline[open problem].

#pause

#feature-block("Effect Systems to the rescue")[
  *Effect systems* are a possible solution to this problem.
]

// #v(1em)

// #align(center)[
//   A possible solution is to use *effects systems*.
// ]

= Effects

== What is an *effect*?

#note-block([Possible _effect_ definition])[
  _Effects_ are #underline[aspects of the computation] that go beyond describing #bold[shapes of values].
]

In a #underline[strongly typed language], we #emph[want] to use the type system to *track them*.

=== What is an effect?

#underline[What] is modeled as an *effect* is a question of language or library design.

- #bold[Reading] or #bold[writing] to mutable state outside functions
- #bold[Throwing] an exception to indicate abnormal termination
- #bold[IO] operations
- #bold[Network] operations
- #bold[Suspending] or #bold[resuming] computations

== What is an effect system?

#feature-block("Effect Systems")[
An *Effect system* extends the guarantees of programming languages from type safety to _effect safety_: all the effects are #underline[eventually handled], and not accidentally handled by the wrong handler.
]

#focus-slide[How many of you *have dealt* with an effect system?]

== Java Checked Exceptions

```java
public String readFile(String path) throws IOException {
    // read file content
}
```
The `throws IOException` clause is an *effect* that indicates that the function may raise an `IOException`.

The compiler #underline[forces] the caller to handle the possible exceptions.

#feature-block("The most adopted form of effect system")[
  Java *checked exceptions* are the most widely adopted effect system in the wild.
]

== Two main approaches

#components.side-by-side[
=== Continuation-passing style

- Explicit control flow manipulation
- Enables advanced patterns: _non-local returns_, _backtracking_, _coroutines_, ...
- _Powerful_ but *hard to reason about*

][
=== Direct style

- Effects are typically modeled _directly_ in the language
- Simpler control flow _tracking_
- Code _closer_ to *imperative* style and *easier* to reason about
]

== The two styles in Scala

=== Monad-based effect systems

```scala
def op(id: Int): ZIO[Config & Logger, Error, Result] =
  for
    config <- ZIO.service[Config]
    _ <- ZIO.logInfo(s"Processing $id")
    result <- if (id < 0) ZIO.fail(InvalidIdError)
              else ZIO.succeed(compute(id))
  yield result
```

Everything is `flatMap`ped.

Requires to deeply #bold[understand] the library.

When the #bold[complexity] increases, the monadic type may becomes more complex,
and *difficult to reason about*.

=== Direct-style effect systems

```scala
def op(id: Int): (Config, Logger) ?=> Either[Error, Result] =
  Log.log(s"Processing $id")
  if (id < 0) Left(InvalidIdError)
  else Right(compute(id))
```

Also in this case the *effects* are _explicitly_ defined in the function signature.

The implementation is _closer_ to the *imperative style*, and the _effects_ are _directly_ handled in the code.

== Pros and Cons\*

#components.side-by-side[
  === Direct style
  #fa-circle-check() *Easier* to reason about \
  #fa-circle-check() *Easier* to compose \
  #fa-circle-check() *Less* "boilerplate" \
  #fa-circle-xmark() *Problems* with higher-order functions \
][
  === Monadic style
  #fa-circle-check() *Powerfull* way to handle effects \
  #fa-circle-check() Usually *safer* than direct-style \
  #fa-circle-xmark() *More* complex to reason about \
  #fa-circle-xmark() Requires *confidence* with the library \
]

#v(1.5em)

#only("2")[
  #align(center)[
    \*That's my *personal interpretation*! #fa-smile()
  ]
]
// == Downsides of both approaches

// #components.side-by-side[
//   === Direct Style

//   #fa-circle-xmark() 
  
// ][
//   === Monadic Style

//   #fa-circle-xmark() *Overprovision* of effects \
//   #fa-circle-xmark() Effects are not (easily) *composable*\* \
//   #fa-circle-xmark() Good *understanding* of the library \
//   #fa-circle-xmark() *Cognitive load* overhead \
//   #fa-circle-check() *Safe* effect handling (by construction) \
// ]

#focus-slide[
  Where is *`Scala 3`* going?
]

#slide(title: "Where is Scala 3 going?")[
  #figure(image("images/direct-vs-monadic-scala.jpg"))
]

= Safer exceptions in Scala 3

== Why Exceptions?

Exceptions are an *ideal* mechanism for error handling in many situations.

- They #bold[propagates] error conditions with minimal boilerplate;
- #bold[Zero-overhead] for the "happy path";
- Are #bold[debug-friendly], with stack traces and all;

```scala
def readFile(path: String): String =
  val source = Source.fromFile(path)
  try
    source.getLines().mkString("\n")
  finally
    source.close()
```

== Why not Exceptions?

Exceptions in Scala and many other languages *are not reflected* in the type system. \
This means that an #bold[essential] part of the function's contract is not *statically checked*.

#components.side-by-side(columns: (auto, 1fr))[
  A #strike[good] example are *Java checked exceptions*:

  - Do the #bold[right thing], in principle;
  - Widely regarded as a #bold[mistake] (difficult to deal with)
][
  #figure(image("images/java-checked-exceptions.jpg", width: 100%))
]

None of the Java' successor or build in the JVM has copied this mechanism.

Anders Hejlsberg's statement on why C\# does not have checked exceptions. #footnote(link("https://www.artima.com/articles/the-trouble-with-checked-exceptions"))

== The problem with Java's checked exceptions

Java's checked exceptions are #bold[inflexible], due to *lack of polymorphism*.

```scala
  def map[B](f: A => B): List[B]
```

In the Java model, function `f` #bold[is not allowed] to throw checked exceptions.

The following code is invalid:

```scala
xs.map(x => if x < limit then x * x else throw LimitExceeded())
```

A workaround is to #bold[wrap] the exception in an unchecked one:

```scala
try
  xs.map(x => if x < limit then x * x else throw Wrapper(LimitExceeded()))
catch case Wrapper(ex) => throw ex
```

Ugh! That's why checked exceptions in Java are not very popular #fa-smile()

== Monadic effects -- The dilemma

/ Dilemma: Exceptions are easy to use only as long we #underline[forget static type checking].

A popular alternative solution is to use the #bold[error monad], aka `Either`:

```scala
def readFile(path: String): Either[IOException, String] = ...
```

This approach #bold[enables] static checking of possible errors, however:

- Make the code #bold[more complex] to #bold[harder to refactor]
- The classical problem of #bold[composing] with other monadic effects

== From Effects to Capabilities

The `map` function work so poorly with checked exceptions because forces the parameters *to not throw* any checked exception.

```scala
def map[B, E](f: A => B throws E): List[B] throws E
```

This assumes a type `A throws E` to indicate a computation of type `A` that may throw exceptions of type `E`.

#fa-warning() Lot of *cerimony* we don't want to deal with!

#pagebreak()

There is a way to avoid all this #bold[cerimony] by *changing the way we think about effects*.

#feature-block("From effects to capabilities")[
Instead of concentrating on #bold[possible effects] such as _"this code might throw an exception"_, concentrate on *capabilities* such as _"this code needs the capability to throw an exception"_.
]

== The `CanThrow` capability

#note-block("Effect as capability")[
  In the "effect as capability" approach, an *effect* is modeled as an (implicit) parameter of a #underline[certain type].
]

```scala
erased class CanThrow[-E <: Exception]
```

For exceptions, the capability is `CanThrow[E]`, meaning that the code is allowed to throw exceptions of type `E`.

```scala
infix type throws[R, -E <: Exception] = CanThrow[E] ?=> R
```

```scala
def m[T](x: T)(using CanThrow[E]): T
def m[T](x: T): T throws E
```

#pagebreak()

```scala
def m(x: T): U throws E1 | E2
def m(x: T): U throws E1 throws E2
def m(x: T)(using CanThrow[E1], CanThrow[E2]): U
def m(x: T)(using CanThrow[E1])(using CanThrow[E2]): U
def m(x: T)(using CanThrow[E1]): U throws E2
```

The `CanThrow/throws` capability propagates the `CanThrow` requirement outwards. But how this capability is created?

```scala
try
  erased given CanThrow[Ex1 | ... | ExN] = compiletime.erasedValue
  body
catch ...
```

= Example

== Example
// Enable the experimental feature:
// ```scala
// import language.experimental.saferExceptions
// ```

Define a `LimitExceeded` exception and a function that may throw it:

```scala
val limit = 10e9
class LimitExceeded extends Exception
def f(x: Double): Double =
  if x < limit then x * x else throw LimitExceeded()
```

#only("2")[
We get this compile-time error:

#local(number-format: none, zebra-fill: none, fill: luma(240),
```
  if x < limit then x * x else throw LimitExceeded()
                               ^^^^^^^^^^^^^^^^^^^^^
The capability to throw exception LimitExceeded is missing.
```
)
]

#pagebreak()

```scala
def f(x: Double): Double throws LimitExceeded =
  if x < limit then x * x else throw LimitExceeded()
```

The capability is injected by the `try/catch` block.

```scala
@main def test(xs: Double*) =
  try println(xs.map(f).sum)
  catch case ex: LimitExceeded => println("too large")
```

== Caveats

The current capability model allows to *declare* and *check* the thrown exceptions of #underline[first-order] code.

But as it stands, it does not give us enough mechanism to enforce the absence of capabilities for arguments to *higher-order* functions.

```scala
def escaped(xs: Double*): () => Int =
  try () => xs.map(f).sum
  catch case ex: LimitExceeded => () => -1
```

#pagebreak()

Expands to:

```scala
// compiler-generated code
def escaped(xs: Double*): () => Int =
  try
    given ctl: CanThrow[LimitExceeded] = ???
    () => xs.map(x => f(x)(using ctl)).sum
  catch case ex: LimitExceeded => -1
```

But if you try to call escaped like this:

```scala
val g = escaped(1, 2, 1000000000)
g() // throws LimitExceeded even if we enclosed it in a try/catch
```

#pagebreak()

What's missing is that `try` #bold[should enforce] that the capabilities it generates *do not escape* as free variables in the result of its body.

It makes sense to describe such scoped effects as *ephemeral capabilities*-they have #bold[lifetimes] that cannot be extended to delayed code in a lambda.
#v(2em)
#only("2")[
  #align(center)[#text(size: 1.2em)[Hey, some #fa-rust() vibes here!]]
]

= Capture Checking

== Motivating Example

```scala
def usingLogFile[T](op: FileOutputStream => T): T =
  val logFile = FileOutputStream("log")
  val result = op(logFile)
  logFile.close()
  result
```

At a first look, this code #bold[seems to be correct], but...

#only("2")[
  === Problematic Code
  ```scala
  val later = usingLogFile { file => (y: Int) => file.write(y) }
  later(10) // crash
  ```

  When `later` is executed it tries to write to a closed file.
]

Code example: `01-leaking-logger.scala`

== Capture Checking

*Capture Checking* enables to spot this kind of problems #bold[statically].

_Capture Checking_ is an experimental feature in Scala 3 that can be enabled with:
```scala
import language.experimental.captureChecking
```
It is possible to re-write the previous code as follows:

```scala
def usingLogFile[T](op: FileOutputStream^ => T): T =
  val logFile = FileOutputStream("log")
  val result = op(logFile)
  logFile.close()
  result
```

The `^` turns the `FileOutputStream` into a *capability*, whose #bold[lifetime] is tracked.

== Compile-time Error

If we try to execute the problematic code again, we get a #emph[compile-time error]:
#local(number-format: none, zebra-fill: none, fill: luma(240),
```
[error] ./code/01-leaking-logger.scala:7:13
[error] local reference f leaks into outer capture set of type parameter T of method usingLogFile in object LeakingLogger
[error]     val a = usingLogFile { f => () => f.write(0) }
[error]             ^^^^^^^^^^^^
```
)

It is trivial to observe that `logFile` capability *escapes* in the closure passed to `usingLogFile`.

But of course, this mechanism is able to detect more #emph[complex cases].

== Rust analogy

This mechanism is similar to the #bold[lifetimes] and #bold[borrowing] mechanism in #fa-rust():

```rust
fn using_log_file<T>(op: impl FnOnce(&mut File) -> T) -> T {
    let mut log_file = File::create("log").unwrap();
    let result = op(&mut log_file);
    // log_file is automatically closed here (Drop trait)
    result
}
```

#pagebreak()

Calling code:

```rust
using_log_file(|f| { || { f.write(&[0]) } });
```
#text(size: 0.7em)[
#local(number-format: none, zebra-fill: none, fill: luma(240),
```
error: lifetime may not live long enough
  --> src/main.rs:13:26
   |
13 |     using_log_file(|f| { || { f.write(&[0]) } });
   |                     --   ^^^^^^^^^^^^^^^^^^^^ returning this value requires that `'1` must outlive `'2`
   |                     ||
   |                     |return type of closure `{closure@src/main.rs:13:26: 13:28}` contains a lifetime `'2`
   |                     has type `&'1 mut File`
```
)
]


== Complex Example

*Capture checking* is able to distinguish between the following two cases:

Who is #text(fill: green)[correct] and who is #text(fill: red)[not]?

#components.side-by-side[
```scala
val xs = usingLogFile: f =>
  List(1,2,3).map: x =>
    f.write(x)
    x * x
```
#only("2")[
  #align(center)[
    #fa-check-circle()
  ]
]
][
```scala
val xs = usingLogFile: f =>
  LazyList(1,2,3).map: x =>
    f.write(x)
    x * x
```
#only("2")[
  #align(center)[
    #fa-xmark-circle()
  ]
]
]

#only("3")[
  Note: this assume a "capture-aware" implementation of `LazyList`.
]


== Applicability

*Capture checking* has very broad applications:

- Keeps track of #bold[checked exceptions] enabling a clean and fully safe system of exceptions.
- Address the problem of #bold[effect polymorphism] in general.
- Solve the problem of _"what color is you function?"_ (mixing sync and async computations).
- Enables "region-based" allocation (safely).
- Reason about capabilities associated with memory locations.

== Capability

A *capability* is (syntactically) a #emph[method], or a #emph[class-paramter], a #emph[local variable], or the `this` of an enclosing class.

The *type* of a capability must be a _capturing type_ with a non-empty capture set.
Values that are *capabilities* are also _tracked_.

Every *capability* gets its autority from some other, more #emph[sweeping] capability which it captures.

The most sweeping capability (from which all others are derived) is `cap` (universal capability).

If `T` is a type, then `T^` is a capability type with capture set `{cap}`,
meaning that `T` can capture #emph[any capability].

== Capability Hierarchy

```scala
class FileSystem
class Logger(fs: FileSystem^):
  def log(s: String): Unit = ... // Write to a log file, using `fs`
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
// Code example: `02-logger-example.scala`

== Capabilities and Capturing Types

Capture checking is done in term of _captuing types_ of the form $T\^{c_1,c_2,dots,c_n}$.
- $T$ is a type
- ${c_1,c_2,dots,c_n}$ is a *capture set* consisting of references to capabilities $c_1,c_2,dots,c_n$

#align(center)[
  `{cap}` is the root, more sweeping capability.
]

== Function Types

=== Impure Functions
Functions type like `A => B` now means that the function can capture #underline[arbitrary capabilities].

Those functions are called *impure functions*.

=== Pure Functions

The "thin arrow" `A -> B` means that the function #underline[cannot capture any capability].

Those functions are called *pure functions*.

A capture set to *pure functions* can be added later on `A ->{c,d} B` meaning that the function can capture #emph[only] `c` and `d`, and no others.

This syntax is a short-hand for `(A -> B)^{c,d}`.

`A => B` is an alias for `A ->{cap} B` (impure function that can capture anything).

The same convention applies to #emph[context functions]

`A ?=> B` is an impure context function, with `A ?-> B` as its pure counterpart.

=== Methods

The distinction between pure and impure function do not apply to methods.

Since methods are not values, they #underline[never] capture anything directly.

Reference to capabilities in a method are counted in the *capture set* of the #underline[enclosing object].

== By-Name Parameters Types

Given a function with a by-name parameter:

```scala
def f(x: => Int): Int

f(if p(y) then throw Ex() else 1)
```

The actual argument `x` can refer to arbitrary capabilities.

So the call above is allowed.

== By-Name Parameters Types

```scala
def f(x: -> Int): Int
```

the actual argument to `f` could not refer to any capabilities, so the call above would be rejected.

```scala
def f(x: ->{c} Int): Int
```

the argument `f` is allowed to use the capability `c`, but not any other.

Code example: `03-thin-fat-arrow.scala`

== Subtyping Relation

Capturing types comes with a *subtyping* relation:

#quote[capturing types with "smaller" capture sets are #underline[subtypes] of types with larger capture sets]

If a type `T` does not have a #emph[capture set], then it is called *pure*, and it is a #emph[subtype] of any capturing type that adds a capture set to `T`.

#align(center)[
  $T <: T #math.hat {c_1,c_2} <: T #math.hat {c_1,c_2,dots,c_n}$ 

  $T_1\^C_1 <: T_2\^C_2$ if $C_1 <: C_2$ and $T_1 <: T_2$
  #v(1em)
]
A subcapturing relation $C_1 <: C_2$ holds if $C_2$ #bold[accounts] for all the capabilities in $C_1$.

// That means that one of the following condition must be true:
// - $c in C_2$
// - $c$'s type has a captuing set $C$ and $C_2$ #bold[accounts] for all the capabilities in $C$.

== Escape Checking

#feature-block("Escape Checking")[
  *Capabilities* follow the _scoping discipline_, meaning that capture sets can contain only capabilities that are visible at the point where the set is defined.
]

== Reasoning steps for raising the error

// ```scala
// def usingLogFile[T](op: FileOutputStream^ => T): T =
//   val logFile = FileOutputStream("log")
//   val result = op(logFile)
//   logFile.close()
//   result
// val later = usingLogFile { file => (y: Int) => file.write(y) }
// ```

#local(number-format: none, zebra-fill: none, fill: luma(240),
```
  val later = usingLogFile { f => () => f.write(0) }
                         ^^^^^^^^^^^^^^^^^^^^^^^^^
  ./01-leaking-logger.scala:7:26
  Found:    (f: java.io.FileOutputStream^) ->'s2 () ->{f} Unit
  Required: java.io.FileOutputStream^ => () ->'s3 Unit
  
  Note that capability f cannot be included in outer capture set 's3.
```
)

1. The parameter `file` has type `FileOutputStream^` making it a *capability*;
2. Therefore, the type of the expression: `() ->{f} Unit`;
3. Consequently, `(f: FileOutputStream^) =>'s2 () ->{f} Unit`, for some set `'s2`;
4. The closure type is `FileOutputStream^ => T` for some instantiated type `T`;
5. `T` must have shape `() ->'s3 Unit`, for some set `'s3` at `later` level;
6. That set cannot include `f`, since `f` is not in scope at that level;

== Restrictions for mutable variables

Another restriction applies to #bold[mutable variables].

```scala
var loophole: () => Unit = () => ()
usingLogFile { f =>
  loophole = () => f.write(0)
}
loophole()
```

This will not compile either, since the _capture set_ of `loophole` cannot refer to `f`,
which is not in scope at that level.

#focus-slide[
  How can CC be used for more *safe* effecfull computation?
]

== IO example

Let's try to build a simple *IO-based* program that can #bold[read] and #bold[write] to a _file_ or to the _console_.

```scala
trait IO:
  def println(content: String): Unit
  def read[R](combine: IterableOnce[String] => R): R
```

And our *effect type* is the following:

```scala
type EffectIO[R] = IO ?=> R
```

Pretty straightforward, right?

Code example: `04-unsafe-io.scala`

== Downsides

Let's try to run the following code:

```scala
def main(args: Array[String]): Unit =
  val res = IO.runWithHandler(doubleItAndPrint(5))(using
    fileHandler(Path.of("input.txt"))
  )
  println(res)

def unsafeReadFile: EffectIO[IterableOnce[String]] =
  IO.read(identity)
```

Something very nasty happens here...

== Runtime Error

Executing the code above will result in a runtime error:

```scala
Exception in thread "main" java.io.IOException: Stream Closed
        at java.base/java.io.FileInputStream.readBytes(Native Method)
        at java.base/java.io.FileInputStream.read(FileInputStream.java:276)
        ...
```

With *Capture Checking* we can rule out this kind of problems.

== Capture-aware IO Implementation

```scala
type EffectIO[R] = IO ?=> R

trait IO:
  def println(content: String): Unit
  def read[R](combine: IterableOnce[String]^ => R): R

object IO:
  def run[R](program: EffectIO[R]): R^{program} =
    run(program)(using consoleHandler)
  def run[R](program: EffectIO[R])(using io: IO): R^{program} =
    program(using io)
```

This *capture-aware* implementation of `IO` is able to intercept the example above and throw a compile-time error.

== Capture-aware IO Implementation

If we try to compile the same code with the *capture-aware* implementation of `IO`, we get a compile-time error:

#local(number-format: none, zebra-fill: none, fill: luma(240),
```
Found:    (x: IterableOnce[String]^'s1) ->'s2 (IterableOnce[String]^'s3)?
Required: IterableOnce[String]^ => (IterableOnce[String]^'s4)?

Note that capability cap is not included in capture set {}.
```
)

Any unsafe usage of `read` will be caught at compile time.

Code example: `05-safer-io.scala`

= Capability Polymorphism

== 

It is convenient sometimes to write operations *parametrized* over a capture set of capabilities.

Consider a `Source` on which `Listeners` can be registered and which they can hold certain capabilities.

```scala
class Source[X^]:
  private var listeners: Set[Listener^{X}] = Set.empty
  def register(x: Listener^{X}): Unit =
    listeners += x

  def allListeners: Set[Listener^{X}] = listeners
```

The type variable `X^` can be instantiated with a set of arbitrary capabilities.
Thus, `X` #bold[can occur] in capture sets in *its scope*.

== Example

Capture-set variables can be #bold[inferred] like regular type variables. When they should be instantiated #bold[explicitly] one supplies a concrete capture set. For instance:

```scala
class Async extends caps.SharedCapability

def listener(async: Async): Listener^{async} = ???

def test1(async1: Async, others: List[Async]) =
  val src = Source[{async1, others*}]
  ...
```

Here `src` is instantiated to `Source` on which listeners can refer to the `async1` capability,
or to any of the capabilities in `others`.

#pagebreak()

The following code is valid:

```scala
src.register(listener(async1))
others.map(listener).foreach(src.register)
val ls: Set[Listener^{async, others*}] = src.allListeners
```

= Capability Classifiers

== Introduction

Capabilities are *extremely versatile*.

#components.side-by-side[
They may represents:
- Exceptions
- Continuations,
- I/O
- Mutation
- Information flow
- security permissions
- ...
][
  Sometimes we want to #bold[restrict] or #bold[classify] what kind of capabilities are expected or returned in a context.

  We might want only *control* capabilities such as `CanThrow` or `Label`s but no others.

  Or we only want *mutation*, but no other capabilities.
]

#pagebreak()

For instance

```scala
trait Control extends SharedCapability, Classifier
```

The Gears library #footnote(link("https://github.com/lampepfl/gears")) uses the `Control` classifier in its `Async` definition:

```scala
trait Async extends Control
```

#warning-block("Restriction")[
  Unlike normal inheritance, classifiers #bold[restrict] the capture set of a capability.
]

== Example

```scala
def f(using async: Async) = body
```

We have the guarantee that any capabilities captured by `async` *must* be a `Control` capability.

A classifier is a `class` or `trait` extending *directly* the `Classifier` trait.

So with definition, `Control` is a classifier trait, but `Async` is not, since it extends `Classifier` indirectly through `Control`.

#note-block("Classifiers are unique")[
A class cannot extend directly or transitively at the same time two unrelated classifier traits.
If a class transitively extends two classifier `C1` and `C2`, then one of them must be a #bold[subtrait] of the other.
]

== Predefined Classifiers

```scala
trait Classifier

sealed trait Capability

trait SharedCapability extends Capability Classifier
trait Control extends SharedCapability, Classifier

trait ExclusiveCapability extends Capability, Classifier
trait Mutable extends ExclusiveCapability, Classifier
```

= Separation Checking

== Introduction

*Separation Checking* /*#cite(label("DBLP:journals/pacmpl/XuBO24"))*/ is an extension of the _capture checking_ that enforces unique, un-aliased access to capabilities.

#feature-block("Separation Checking")[
  The purpose of *separation checking* is to ensure that certain accesses to capabilities are #bold[not aliased].
]

- Statically prevents #underline[data races] in parallel programming
- Tracks #underline[aliasing] and controls #underline[mutable] state access

== Example

#feature-block("Control as you need")[
  Aliases are allowed by default, but #bold[tracked] and #bold[controlled] when necessary to prevent data races.
]

Consider matrix multiplication:

```scala
def multiply(a: Matrix, b: Matrix, c: Matrix): Unit
```

Such signature formulation do not tell us which matrices are supposed to be _inputs_, and which one is the _output_.

It #bold[does not guarantee] that an input matrix is not re-used as output matrix.

== With Separation Checking

With separation checking, we can write:

```scala
class Matrix(nrows: Int, ncols: Int) extends Mutable:
  update def setElem(i: Int, j: Int, x: Double): Unit = ???
  def getElem(i: Int, j: Int): Double = ???
```

We declare the `setElem` method with the `update` modifier, indicating that it has *side effects*.

#pagebreak()

With separation checking, the following definition has a #bold[special] meaning:

```scala
def multiply(a: Matrix, b: Matrix, c: Matrix^): Unit
```

Now `c` carries the _universal capability_.

The following _two_ properties are ensured:

- Matrices `a`, and `b` are #bold[read-only]. `multiply` will not call their update method.
- Matrices `a`, and `b` #bold[are different] from `c`. But `a` and `b` may refer to the same matrix.

=== Unaliased access

Effectively, anything that can be updated must be *unaliased*.

== The `Mutable` trait

```scala
trait Mutable extends ExclusiveCapability, Classifier
```

It is used to types that define *update methods* using a new soft modifier `update`.

=== Example

```scala
class Ref(init: Int) extends Mutable:
  private var current = init
  def get: Int = current
  update def set(x: Int): Unit = current = x
```

`update` can only be used in classes or objects that extend `Mutable`.

- An #bold[update method] is allowed to access exclusive capabilities in method's env
- A #bold[normal method] may access exclusive capabilities only if they are defined locally, or passed as parameters.

== Mutable Types

#feature-block("Mutable Types Definition")[
  A type is *mutable* if it extends `Mutable` and it has an `update` method (or class) as non-private member or constructor.
]

When we create an instance of a *mutable* type we always add `cap` to its capture set.

```scala
val ref: Ref[Int]^ = new Ref[Int](0)
```
== Read-only Capabilities

if `x` is an exclusive capability of a type extending `Mutable`, `x.rd` is its associated *read-only* capability.

It can be considered as a #bold[shared capability].

#warning-block("Read-only capability")[
  A read-only capability #bold[does not allow] access to mutable fields.
]

== Implicitly added capture sets

A reference to a type extending `Mutable` gets an implicit capture set `{cap.rd}` when *no explicit capture set* is provided.

```scala
def mul(a: Matrix, b: Matrix, c: Matrix^): Unit
```

expands to:

```scala
def mul(a: Matrix^{cap.rd}, b: Matrix^{cap.rd}, c: Matrix^{cap}): Unit
```

Separation checking will ensure that `a` and `b` are different from `c`.

== Separation checking flexibility

Consider the following code:

```rust
struct Vec2 { x: i32, y: i32 }

fn update<F, G>(p: &mut Vec2, mut f: F, mut g: G)
  where F: FnMut(&i32) -> i32, G: FnMut(&i32) -> i32 {
    p.x = f(&p.x); p.y = g(&p.y);
}

fn main() {
    let mut p = Vec2 { x: 1, y: 2 };
    let mut sum = 0;
    update(&mut p, |&x| { sum += x; x + 1 }, |&y| { sum += y; y + 1 });
}
```

#text(size: 0.69em)[
  #local(number-format: none, zebra-fill: none, fill: luma(240),
  ```
  error[E0499]: cannot borrow `sum` as mutable more than once at a time
    --> src/main.rs:11:46
    |
  11 |     update(&mut p, |&x| { sum += x; x + 1 }, |&y| { sum += y; y + 1 });
    |     ------         ----   ---                ^^^^   --- second borrow occurs due to use of `sum` in closure
    |     |              |      |                  |
    |     |              |      |                  second mutable borrow occurs here
    |     |              |      first borrow occurs due to use of `sum` in closure
    |     |              first mutable borrow occurs here
    |     first borrow later used by call
  ```
  )
]

Arguably, this is a #underline[reasonable] programming pattern...

In the last line of main, although both closures *retain a mutable alias* to sum, the two closures #bold[execute sequentially], thus being devoid of data races.

== Concurrent updates

With *separation checking* we want to statically reject code suffering from #bold[data races]:

#show raw: set text(size: 1em)
```scala
def seq(f: () => Unit; g: () ->{cap, f} Unit): Unit =
  f(); g()
```

Here, the `g` parameter explicitly mentions `f` in its potential capture set.

This means that the `cap` in the same capture set would #bold[not need to hide] the first argument, since *it already appears explicitly in the same set*.

```scala
val r = Ref(1)
val plusOne = r.set(r.get + 1)
seq(plusOne, plusOne)
```

== Wrapping up

#components.side-by-side(columns: (1.5fr, 2fr))[
  #figure(image("images/oxidizing-scala.png", width: 100%))
][
  - Scala 3 is *oxidizing* towards more #bold[safe] effect handling
    - A lot of #fa-rust() vibes!
  - *Capabilities* are a powerful and #bold[general] way to model effects
  - Bring *more safety* without sacrificing #bold[ease of use]
  - Still highly #bold[experimental]
    - Oriented for _library authors_
    - More safe _stdlib_
]

// They are pursuing the #bold[direct-style] approach to model effects in Scala 3.

// This simplify the code and make it #underline[easier to reason about].

// But *less safe* than the monadic approach.

// The *capture checking* mechanism is able to catch a lot of problems at compile time trying to have more safety in the #bold[direct-style] approach.

