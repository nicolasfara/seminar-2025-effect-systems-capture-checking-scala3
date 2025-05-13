//> using option -language:strictEquality
//> using option -language:experimental.saferExceptions
//> using option -Yexplicit-nulls
import java.io.IOException
import scala.collection.immutable.Stream.Cons
import java.nio.file.Path
import scala.util.Using
import java.io.PrintWriter

trait Computation[R] extends (() => R):
  def run(): R = apply()

trait IO:
  def write(content: String): Unit throws IOException
  def read[R](combine: IterableOnce[String] => R): R throws IOException

object IO:
  /** IO handlers based on file
    */
  def fileHandler(path: Path): IO = new IO:
    override def read[R](combine: IterableOnce[String] => R): R throws IOException =
      val data = scala.io.Source.fromFile(path.toString).getLines()
      combine(data)

    override def write(content: String): Unit throws IOException =
      Using(PrintWriter(path.toFile)): fos =>
        fos.write(content)
      .get

  /** IO handlers based on console
    */
  given consoleHandler: IO with
    override def read[R](combine: IterableOnce[String] => R): R throws IOException =
      val data = scala.io.StdIn.readLine.linesIterator
      combine(data)

    override def write(content: String): Unit throws IOException =
      println(content)

  def write(content: String)(using io: IO): Unit throws IOException =
    io.write(content)

  def read[R](combine: IterableOnce[String] => R)(using io: IO): R throws IOException =
    io.read(combine)

  def apply[R](body: IO ?=> R)(using t: CanThrow[IOException]): Computation[R] = () =>
    body(using consoleHandler)

  def file[R](path: Path)(body: IO ?=> R): R throws IOException = body(using fileHandler(path))

object UnsafeIO:
  import IO.{*, given}

  def main(args: Array[String]): Unit =
    try
      val res = IO:
        IO.write("Starting IO operations")
        IO.file(Path.of("input.txt")):
          IO.write("Reading a file")(using consoleHandler)
          val res = IO.read(_.iterator.mkString)
          IO.write(s"Hello, World: $res")(using consoleHandler)
      res.run()
    catch case e: IOException => println(s"An error occurred: ${e.getMessage}")
