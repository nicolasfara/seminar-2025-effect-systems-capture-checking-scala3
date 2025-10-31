//> using option -language:strictEquality
//> using option -language:experimental.captureChecking
//> using option -language:experimental.saferExceptions
//> using option -Xprint:cc Prints
//> using option -Yexplicit-nulls

object ThinFatArrows:
  def main(args: Array[String]): Unit =
    val input = args(0).toInt
    // try
      val res = doubleIt:
        if (input < 0) then throw new Exception("Negative number")
        else input
      println(res)
    // catch case e: Exception => println(e.getMessage)

  def doubleIt(f: => Int): Int = f * 2
  // def doubleIt(f: -> Int): Int = f * 2
