error id: D908CB8FBF7868DEE00977D18F74903F
file://<WORKSPACE>/code/01-leaking-logger.scala
### java.lang.IndexOutOfBoundsException: -1

occurred in the presentation compiler.



action parameters:
offset: 215
uri: file://<WORKSPACE>/code/01-leaking-logger.scala
text:
```scala
//> using option -language:experimental.captureChecking
import java.io.FileOutputStream

object LeakingLogger:
  def main(args: Array[String]): Unit =
    val a = usingLogFile { f => () => f.length() }
    println(a@@() // This will leak the log file

  def usingLogFile[T](op: String^ => T): T =
    // val logFile = FileOutputStream("log")
    val str = "log"
    val result = op(str)
    // logFile.close()
    str.appended('f')
    result

```


presentation compiler configuration:
Scala version: 3.7.0-bin-nonbootstrapped
Classpath:
<WORKSPACE>/.scala-build/seminar-2025-effect-systems-capture-checking-scala3_d5c0a6989e/classes/main [exists ], <HOME>/.cache/coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala3-library_3/3.7.0/scala3-library_3-3.7.0.jar [exists ], <HOME>/.cache/coursier/v1/https/repo1.maven.org/maven2/org/scala-lang/scala-library/2.13.16/scala-library-2.13.16.jar [exists ], <HOME>/.cache/coursier/v1/https/repo1.maven.org/maven2/com/sourcegraph/semanticdb-javac/0.10.0/semanticdb-javac-0.10.0.jar [exists ], <WORKSPACE>/.scala-build/seminar-2025-effect-systems-capture-checking-scala3_d5c0a6989e/classes/main/META-INF/best-effort [missing ]
Options:
-language:experimental.captureChecking -Xsemanticdb -sourceroot <WORKSPACE> -Ywith-best-effort-tasty




#### Error stacktrace:

```
scala.collection.LinearSeqOps.apply(LinearSeq.scala:129)
	scala.collection.LinearSeqOps.apply$(LinearSeq.scala:128)
	scala.collection.immutable.List.apply(List.scala:79)
	dotty.tools.dotc.util.Signatures$.applyCallInfo(Signatures.scala:244)
	dotty.tools.dotc.util.Signatures$.computeSignatureHelp(Signatures.scala:101)
	dotty.tools.dotc.util.Signatures$.signatureHelp(Signatures.scala:88)
	dotty.tools.pc.SignatureHelpProvider$.signatureHelp(SignatureHelpProvider.scala:46)
	dotty.tools.pc.ScalaPresentationCompiler.signatureHelp$$anonfun$1(ScalaPresentationCompiler.scala:479)
```
#### Short summary: 

java.lang.IndexOutOfBoundsException: -1