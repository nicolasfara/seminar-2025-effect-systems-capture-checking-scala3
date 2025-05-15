#import "@preview/touying:0.6.1": *
#import themes.metropolis: *
#import "@preview/fontawesome:0.5.0": *
#import "@preview/ctheorems:1.1.3": *
#import "@preview/numbly:0.1.0": numbly
#import "utils.typ": *

// Pdfpc configuration
// typst query --root . ./example.typ --field value --one "<pdfpc-file>" > ./example.pdfpc
#let pdfpc-config = pdfpc.config(
    duration-minutes: 30,
    start-time: datetime(hour: 14, minute: 10, second: 0),
    end-time: datetime(hour: 14, minute: 40, second: 0),
    last-minutes: 5,
    note-font-size: 12,
    disable-markdown: false,
    default-transition: (
      type: "push",
      duration-seconds: 2,
      angle: ltr,
      alignment: "vertical",
      direction: "inward",
    ),
  )

#let proof = thmproof("proof", "Proof")

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-common(
    // handout: true,
    preamble: pdfpc-config,
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
    // institution: [University of Bologna],
    // logo: align(right)[#image("images/disi.svg", width: 55%)],
  ),
)

#set text(font: "Fira Sans", weight: "light", size: 20pt)
#show math.equation: set text(size: 20pt)

#set raw(tab-size: 4)
#show raw: set text(size: 1em)
#show raw.where(block: true): block.with(
  fill: luma(240),
  inset: (x: 1em, y: 1em),
  radius: 0.7em,
  width: 100%,
)

#show bibliography: set text(size: 0.75em)
#show footnote.entry: set text(size: 0.75em)

// #set heading(numbering: numbly("{1}.", default: "1.1"))

#title-slide()

// == Outline <touying:hidden>

// #components.adaptive-columns(outline(title: none, indent: 1em))

= What we care about

== Reasoning & Composition

One of core values of #bold[functional programming] are *reasoning* and *composition*.

_*Side effects*_ stops us from achieving this goal.

But every (useful) program has to #underline[interact] with the outside world.

In #bold[functional programming], replacing _side effects_ with something that helps achieving these goals is a #underline[open problem].

#v(1em)

#align(center)[
  A possible solution is to use *effects systems*.
]

= Effects

== What is an *effect*?

#quote[_Effects_ are aspects of the computation that go beyond describing shapes of values.]

In a strongly typed language, we #emph[want] to use the type system to #underline[track them].

=== What is an effect?

#underline[What] is modeled as an effect is a question of language or library design.

- _Reading_ or _writing_ to mutable state outside functions
- _throwing and exception_ to indicate abnormal termination
- I/O operations
- _Network_ operations
- _Suspending_ or _resuming_ computations

== What is an effect system?

*Effect systems* extends the guarantees of programming languages from type safety to _effect safety_: all the effects are eventually _handled_, and not accidentally handled by the wrong handler.

#components.side-by-side[
=== Continuation-passing style

- Explicit control flow manipulation
- Enables advanced patterns: _non-local returns_, _backtracking_, _coroutines_, ...
- _Powerful_ composition but *hard to reason about*

][
=== Direct style

- Effects are typically modeled _directly_ in the language
- Simpler control flow _tracking_
- Code _closer_ to *imperative* style and *easier* to reason about
]

== Taste of effect systems types

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

Everything is `flat-mapped`.

Required to deeply #bold[understand] the library.

When the #bold[complexity] increases, the monadic type may becomes more complex,
and *difficult to reason about*.

=== Direct-style effect systems

```scala
def op(id: Int): (Config, Logger) ?=> Either[Error, Result] = {
  Log.log(s"Processing $id")
  if (id < 0) Left(InvalidIdError)
  else Right(compute(id))
}
```

Also in this case the *effects* are _explicitly_ defined in the function signature.

The implementation is _closer_ to the *imperative style*, and the _effects_ are _directly_ handled in the code.

== Direct-style effect systems

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
  #fa-circle-xmark() *More* boilerplate \
  #fa-circle-xmark() *More* complex to reason about \
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

= Motivations

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
  val later = usingLogFile { file => () => file.write(0) }
  later() // crash
  ```

  When `later` is executed it tries to write to a closed file.
]

Code example: `01-leaking-logger.scala`

== Capture Checking

Capture checking enables to spot this kind of problems *statically*.

In Scala, by enabling *Capture Checking* via:
```scala
import language.experimental.captureChecking
```
it is possible to re-write the previous code as follows:

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
```scala
|  val later = usingLogFile { f => () => f.write(0) }
|              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
|The expression's type () => Unit is not allowed to capture the root capability `cap`.
|This usually means that a capability persists longer than its allowed lifetime.
```

It is trivial to observe that `logFile` capability *escapes* in the closure passed to `usingLogFile`.

But of course, this mechanism is able to detect more #emph[complex cases].

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

Note: this assume a "capture-aware" implementation of `LazyList`.

== Applicability

*Capture checking* has very broad applications:

- Keeps track of #bold[checked exceptions] enabling a clean and fully safe system of exceptions.
- Address the problem of #bold[effect polymorphism] in general.
- Solve the problem of _"what color is you function?"_ (mixing sync and async computations).
- Enables "region-based" allocation (safely).
- Reason about capabilities associated with memory locations.

== Capabilities and Capturing Types

Capture checking is done in term of _captuing types_ of the form $T\^{c_1,c_2,dots,c_n}$.
- $T$ is a type
- ${c_1,c_2,dots,c_n}$ is a *capture set* consisting of references to capabilities $c_1,c_2,dots,c_n$

== Capability

A *capability* is (syntactically) a #emph[method], or a #emph[class-paramter], a #emph[local variable], or the `this` of an enclosing class.

The *type* of a capability must be a _capturing type_ with a non-empty capture set.
Values that are *capabilities* are also _tracked_.

Every *capability* gets its autority from some other, more #emph[sweeping] capability which it captures.

The most sweeping capability (from which all others are derived) is `cap` (universal capability).

If `T` is a type, then `T^` is a capability type with capture set `{cap}`,
meaning that `T` can capture #emph[any capability].

== Example

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
Code example: `02-logger-example.scala`

== Subtyping Relation

Capturing types comes with a *subtyping* relation:

#quote[capturing types with "smaller" capture sets are #underline[subtypes] of types with larger capture sets]

If a type `T` does not have a #emph[capture set], then it is called *pure*, and it is a #emph[subtype] of any capturing type that adds a capture set to `T`.

#align(center)[
  $mono(T <: T #math.hat {c_1,c_2} <: T #math.hat {c_1,c_2,dots,c_n})$
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
    runWithHandler(program)(using consoleHandler)

  def runWithHandler[R](program: EffectIO[R])(using io: IO): R^{program} =
    program(using io)
```

This *capture-aware* implementation of `IO` is able to intercept the example above and throw a compile-time error.

== Capture-aware IO Implementation

If we try to compile the same code with the *capture-aware* implementation of `IO`, we get a compile-time error:

```scala
[error] ./05-safer-io.scala:60:13
[error] Found:   (x: IterableOnce[String]^?) ->? box IterableOnce[String]^?
[error] Required:(x: IterableOnce[String]^) => box IterableOnce[String]^?
[error] 
[error] Note that the universal capability `cap`
[error] cannot be included in capture set ?
[error]     IO.read(identity)
```

Any unsafe usage of `read` will be caught at compile time.

Code example: `05-safer-io.scala`

== Wrapping up

They are pursuing the #bold[direct-style] approach to model effects in Scala 3.

This simplify the code and make it #underline[easier to reason about].

But *less safe* than the monadic approach.

The *capture checking* mechanism is able to catch a lot of problems at compile time trying to have more safety in the #bold[direct-style] approach.

