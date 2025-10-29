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
// #show raw: set text(size: 1em)
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
#local(number-format: none, zebra-fill: none, fill: luma(240),
```
|  val later = usingLogFile { file => (y: Int) => file.write(y) }
|              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
|The expression's type Int => Unit is not allowed to capture the root capability `cap`.
|This usually means that a capability persists longer than its allowed lifetime.
```
)

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
Code example: `02-logger-example.scala`

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

== Escape checking

If a *capturing type* is an instance of a #underline[type variable], that capturing type is #underline[not allowed] to carry the *universal capability* `cap`.

The *capture set* of a type has to be present in the _environment_ when the type is instantiated from a type variable.

But `cap` is #bold[not itself available] as a global entity in the environment.

== Reasoning steps for raising the error

```scala
def usingLogFile[T](op: FileOutputStream^ => T): T =
  val logFile = FileOutputStream("log")
  val result = op(logFile)
  logFile.close()
  result

val later = usingLogFile { file => (y: Int) => file.write(y) }
```

1. The parameter `file` has type `FileOutputStream^` making it a *capability*.
2. Therefore, the type of the expression: `Int ->{file} Unit`
3. Consequently, `(file: FileOutputStream^) => Int ->{file} Unit`
4. The closure type is `FielOutputStream^ => T` for some instantiated type `T`.
5. We cannot instantiate `T` with `Int ->{file} Unit` since the *expected function type is not dependent*.
  So the smallest supertype that matches is `Int ->{cap} Unit`.
6. The type variable `T` is instantiated with `Int ->{cap} Unit`, which *is not possible*

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
Found:    (x: IterableOnce[String]^?) ->? IterableOnce[String]^?
Required: IterableOnce[String]^ => IterableOnce[String]^?

where:    => refers to a fresh root capability created in anonymous function of type (using contextual$4: safeio.IO): IterableOnce[String] when checking argument to parameter combine of method read
          ^  refers to the universal root capability
```

Any unsafe usage of `read` will be caught at compile time.

Code example: `05-safer-io.scala`

== Wrapping up

They are pursuing the #bold[direct-style] approach to model effects in Scala 3.

This simplify the code and make it #underline[easier to reason about].

But *less safe* than the monadic approach.

The *capture checking* mechanism is able to catch a lot of problems at compile time trying to have more safety in the #bold[direct-style] approach.

