//> using option -language:strictEquality
//> using option -language:experimental.saferExceptions
//> using option -language:experimental.captureChecking
////> using option -Xprint:cc Prints
//> using option -Yexplicit-nulls

package combining

import java.nio.file.Path
import scala.util.boundary.{Label, break}
import scala.util.Using
import java.io.FileWriter
import scala.util.boundary

type EffectIO[R] = IO ?=> R

trait IO:
  def println(content: String): Unit
  def read[R](combine: IterableOnce[String]^ => R): R

object IO:
  def println(content: String)(using io: IO): Unit = io.println(content)
  def read[R](combine: IterableOnce[String]^ => R)(using io: IO^): R^{io} = io.read(combine)

  def fileHandler(path: Path^): IO^{path} = new IO:
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

  private given consoleHandler: IO with
    override def println(content: String): Unit = scala.Predef.println(content)
    override def read[R](combine: IterableOnce[String]^ => R): R =
      val data = scala.io.StdIn.readLine.linesIterator
      combine(data)

  def run[R](program: EffectIO[R]): R^{program} = runWithHandler(using consoleHandler)(program)
  def runWithHandler[R](using io: IO)(program: EffectIO[R]): R^{program} = program(using io)

type CanRaise[Error] = Label[Left[Error, Nothing]]^

object Raise:
  def raise[L, R](body: Label[Left[L, Nothing]]^ ?=> R): Either[L, R] =
    boundary(Right(body))

  def fail[L, R](error: L)(using Label[Left[L, R]]^): Nothing =
    break(Left(error))

  extension [L, R](either: Either[L, R]^)
    def ?(using l: Label[Left[L, Nothing]]^): R^{l} = either match
      case Left(error) => fail(error)
      case Right(value) => value

// -----------

import IO.{ read, fileHandler }
import Raise.fail

def ifOddLinesRaise: (IO, CanRaise[String]) ?=> String =
  val lineCount = read(_.iterator.size)
  if lineCount % 2 != 0 then fail("File has an even number of lines")
  else read(_.mkString(", "))

@main def main(): Unit =
  val file = Path.of("input.txt")
  val result =
    IO.runWithHandler(using fileHandler(file)):
      Raise.raise:
        ifOddLinesRaise
  result match
    case Left(error) => println(s"Failed with error: $error")
    case Right(value) => println(s"Success with value: $value")
