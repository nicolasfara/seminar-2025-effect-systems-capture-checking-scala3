//> using option -language:strictEquality
//> using option -language:experimental.saferExceptions
//> using option -language:experimental.captureChecking
//> using option -language:experimental.separationChecking
////> using option -Xprint:cc Prints
//> using option -Yexplicit-nulls

import scala.caps.Mutable

class Ref(init: Int) extends Mutable:
  private var current = init
  def get: Int = current
  // def foo(x: Int): Unit = set(current + x)
  update def set(x: Int): Unit = current = x

@main def main(): Unit =
  println("Separation Checking")