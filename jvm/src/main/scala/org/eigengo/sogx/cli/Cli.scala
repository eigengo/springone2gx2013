package org.eigengo.sogx.cli

import org.eigengo.sogx.config.CoreConfig
import java.util.concurrent.Executor
import org.springframework.core.task.SyncTaskExecutor
import org.springframework.context.annotation.{Bean, AnnotationConfigApplicationContext, ImportResource, Configuration}
import java.util.UUID
import org.eigengo.sogx._
import org.springframework.integration.annotation.{Payload, Header}
import scala.annotation.tailrec
import java.io.{InputStream, BufferedInputStream, FileInputStream}

/**
 * Starts the command-line interface that shows that we can very trivially send the messages
 */
object Cli extends App {
  import Commands._
  import Utils.reader._

}

/**
 * Contains command matchers:
 *
 * * ``QuitCommand``  is just a string that matches the string... erm, ``"quit"``
 * * ``ImageCommand`` is a regex matcher that matches inputs ``image:`` followed by any other characters,
 *                    which are extracted
 * * ``MJPEGCommand`` is an object with a custom unapply method that matches ``mjpeg:<name>[?<fps>]``,
 *                    where <name> is the file name and optional <fps> is the frames per second parameter (default 10)
 */
private[cli] object Commands {
  // this is a simple string
  val QuitCommand     = "quit"

  // regex matcher with the proper unapply method
  val ImageCommand    = "image:(.*)".r

  // custom unapply method
  object MJPEGCommand {
    private val regex = "mjpeg:([^?]*)(\\?fps=(\\d+))?".r

    def unapply(input: String): Option[(String, Int)] = {
      input match {
        case regex(fileName, _, fps) => Some((fileName, Option(fps).map(_.toInt).getOrElse(10)))
        case _                       => None
      }
    }
  }
}
