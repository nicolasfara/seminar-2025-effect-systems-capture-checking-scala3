//> using option -language:experimental.captureChecking
import java.io.FileOutputStream

object LeakingLogger:
  def main(args: Array[String]): Unit =
    val a = usingLogFile { f => () => f.write(0) }
    // a: FileOutputStream ->{f} Unit
    a() // This will leak the log file

  def usingLogFile[T](op: FileOutputStream^ => T): T =
    val logFile = FileOutputStream("log")
    val result = op(logFile)
    logFile.close()
    result
