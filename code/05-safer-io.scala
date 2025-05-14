//> using option -language:strictEquality
//> using option -language:experimental.saferExceptions
//> using option -language:experimental.captureChecking
//> using option -Xprint:cc Prints
//> using option -Yexplicit-nulls
package safeio

import java.nio.file.Path
import scala.util.Using
import java.io.FileWriter

type EffectIO[R] = IO ?=> R

trait IO:
  def println(content: String): Unit
  def read[R](combine: IterableOnce[String]^ => R): R

object IO:
  def println(content: String)(using io: IO): Unit = io.println(content)
  def read[R](combine: IterableOnce[String]^ => R)(using io: IO): R = io.read(combine)

  def fileHandler(path: Path): IO = new IO:
    override def println(content: String): Unit =
      Using(FileWriter(path.toFile(), true)): fos =>
        fos.append(content)
        fos.append("\n")
      .get

    override def read[R](combine: IterableOnce[String]^ => R): R =
      Using(scala.io.Source.fromFile(path.toString)): source =>
        val data = source.getLines()
        combine(data)
      .get

  given consoleHandler: IO with
    override def println(content: String): Unit = scala.Predef.println(content)
    override def read[R](combine: IterableOnce[String]^ => R): R =
      val data = scala.io.StdIn.readLine.linesIterator
      combine(data)

  def run[R](program: EffectIO[R]): R^{program} = runWithHandler(program)(using consoleHandler)
  def runWithHandler[R](program: EffectIO[R])(using io: IO): R^{program} = program(using io)

object SafeIO:
  import IO.consoleHandler

  def main(args: Array[String]): Unit =
    val res = IO.runWithHandler(doubleItAndPrint(5))(using consoleHandler)
    println(res)
    // val iteratorResult = IO.runWithHandler(unsafeReadFile)(using fileHandler(Path.of("input.txt")))
    // println(iteratorResult.iterator.mkString(", "))

  def doubleItAndPrint(value: Int): EffectIO[Int] =
    IO.println(s"Doubling: $value")
    val doubled = value * 2
    IO.println(s"Doubled: $doubled")
    doubled

  def unsafeReadFile: EffectIO[IterableOnce[String]] =
    IO.read(identity)