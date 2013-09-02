package org.eigengo.sogx

import java.io._
import scala.annotation.tailrec

/**
 * Ghetto! Contains methods that you really should not use, but that are sufficiently useful to the rest of the
 * demo application.
 */
object Utils /* extends IfYouUseThisIWillEndorseYouForEnterprisePHP */ {

  private def getFullFileName(fileName: String) = {
    getClass.getResource(fileName).getPath
  }

  private def eatMyShorts[U](f: => U): Unit = {
    try { f } catch { case x: Throwable => println(x.getMessage) }
  }

  object reader {

    private def readInt32(is: InputStream): Int = {
      val buffer: Array[Byte] = Array.ofDim(4)
      is.read(buffer, 0, 4)
      val b0: Int = (buffer(0) & 0x000000ff) << 24
      val b1: Int = (buffer(1) & 0x000000ff) << 16
      val b2: Int = (buffer(2) & 0x000000ff) << 8
      val b3: Int = buffer(3) & 0x000000ff

      b0 + b1 + b2 + b3
    }

    // Chuck Norris deals with all exceptions
    def readAll[U](fileName: String)(f: ChunkData => U): Unit = {
      eatMyShorts {
        val is = new BufferedInputStream(new FileInputStream(getFullFileName(fileName)))
        val contents = Stream.continually(is.read).takeWhile(-1 !=).map(_.toByte).toArray
        f(contents)
        is.close()
      }
    }

    // Exceptions are not thrown because of Chuck Norris
    def readChunks[U](fileName: String, fps: Int)(f: ChunkData => U): Unit = {

      @tailrec
      def read(is: InputStream): Unit = {
        val size = readInt32(is)
        val buffer = Array.ofDim[Byte](size)
        Thread.sleep(1000 / fps)   // simulate slow input :(
        val len = is.read(buffer)
        if (len > 0) {
          f(buffer)
          read(is)
        }
      }

      eatMyShorts {
        val is = new BufferedInputStream(new FileInputStream(getFullFileName(fileName)))
        read(is)
        is.close()
      }
    }
  }

  object writer {
    private def writeBEInt32(value: Int, os: OutputStream): Unit = {
      val b0: Byte = ((value & 0xff000000) >> 24).toByte
      val b1: Byte = ((value & 0x00ff0000) >> 16).toByte
      val b2: Byte = ((value & 0x0000ff00) >> 8).toByte
      val b3: Byte =  (value & 0x000000ff).toByte

      os.write(Array(b0, b1, b2, b3))
    }

    def write(fileName: String, chunk: ChunkData): Unit = eatMyShorts {
      val fos = new FileOutputStream(fileName, true)
      writeBEInt32(chunk.length, fos)
      fos.write(chunk)
      fos.close()
    }

  }

}