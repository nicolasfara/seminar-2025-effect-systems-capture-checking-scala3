//> using option -language:strictEquality
//> using option -language:experimental.captureChecking
//> using option -Xprint:cc Prints
//> using option -Yexplicit-nulls

object LoggerExample:
  def main(args: Array[String]): Unit =
    val fs = FileSystem()
    val xs = test(fs)
    println(xs.take(5).toList) // Print the first 5 elements

  class FileSystem:
    def write(s: String): Unit = println(s) // Write to a file

  class Logger(fs: FileSystem^):
    def log(s: String): Unit = fs.write(s) // Write to a log file, using `fs`

  def test(fs: FileSystem^): LazyList[Int]^{fs} =
    val l: Logger^{fs} = Logger(fs)
    l.log("hello world!")
    val xs =
        LazyList.from(1)
        .map { i =>
            l.log(s"computing elem # $i")
            i * i
        }
    xs
