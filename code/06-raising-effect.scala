//> using option -language:strictEquality
//> using option -language:experimental.saferExceptions
//> using option -language:experimental.captureChecking
//// > using option -Xprint:cc Prints
//> using option -Yexplicit-nulls

package raising

import scala.util.boundary.{break, Label}
import scala.util.boundary
import scala.caps.cap

type CanRaise[Error] = Label[Left[Error, Nothing]]

object Raise:
  def raise[L, R](body: Label[Left[L, Nothing]]^ ?=> R): Either[L, R] =
    boundary(Right(body))

  def fail[L, R](error: L)(using Label[Left[L, R]]^): Nothing =
    break(Left(error))

  extension [L, R](either: Either[L, R]^)
    def ?(using l: Label[Left[L, Nothing]]^): R^{either, l} = either match
      case Left(error) => fail(error)
      case Right(value) => value

@main def main(): Unit =
  import Raise.*

  val result = raise:
    List(1, 2, 3).map(i => if i == 2 then fail("Error") else i * 2)

  result match
    case Left(error) => println(s"Failed with error: $error")
    case Right(value) => println(s"Success with value: $value")

  // val captured = raise:
  //   List(1, 2, 3).map(i => if i == 2 then () => fail("Error") else () => i * 2)
  // captured match
  //   case Left(error) => println(s"Failed with error: $error")
  //   case Right(value) => println(s"Success with value: ${value.map(_.apply())}")
