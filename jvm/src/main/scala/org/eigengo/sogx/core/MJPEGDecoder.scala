package org.eigengo.sogx.core

import java.util
import org.eigengo.sogx._
import java.util.Collections

/**
 * Trivial component that simply takes a JPEG frame from the MJPEG stream and returns it as a single element of the
 * decoded frames.
 */
class MJPEGDecoder {

  def decodeFrames(correlationId: CorrelationId, chunk: ChunkData): util.Collection[ImageData] = {
    Collections.singletonList(chunk)
  }

}
