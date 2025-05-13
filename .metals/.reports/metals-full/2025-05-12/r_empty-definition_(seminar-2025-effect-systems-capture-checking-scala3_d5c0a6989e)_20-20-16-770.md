error id: `<none>`.
file://<WORKSPACE>/code/01-leaking-logger.scala
empty definition using pc, found symbol in pc: `<none>`.
empty definition using semanticdb
empty definition using fallback
non-local guesses:

offset: 178
uri: file://<WORKSPACE>/code/01-leaking-logger.scala
text:
```scala
//> using option -language:experimental.captureChecking
object LeakingLogger:
  def main(args: Array[String]): Unit =
    val a = foo { f => () => f.length() }
    print(a())

  @@def foo[T](f: String^ => T): T =
    f("hello")

```


#### Short summary: 

empty definition using pc, found symbol in pc: `<none>`.