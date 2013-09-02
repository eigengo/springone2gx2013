package org.eigengo.sogx.core

import org.springframework.integration.annotation.{Header, Payload}
import java.util.Collections
import org.eigengo.sogx.ContentTypes._
import org.eigengo.sogx._
import java.util

class ChunkDecoder(mjpegDecoder: MJPEGDecoder) {

  /**
   * Take the chunk arriving on a particular correlationId, examine its content type, and attempt to decode as many
   * still frames as possible; now that we have all previous chunks and the new one just arriving.
   *
   * @param correlationId the correlation id
   * @param contentType the content type
   * @param chunk the new chunk
   * @return collection of individual frames (represented as JPEG data)
   */
  def decodeFrame(@Header correlationId: CorrelationId, @Header("content-type") contentType: String,
                  @Payload chunk: ChunkData): util.Collection[ImageData] = contentType match {
    case `video/mjpeg` => decodeMJPEGFrames(correlationId, chunk)
    case `image/*`     => decodeSingleImage(correlationId, chunk)
  }

  private def decodeSingleImage(correlationId: CorrelationId, chunk: ChunkData): util.Collection[ImageData] = Collections.singletonList(chunk)

  private def decodeMJPEGFrames(correlationId: CorrelationId, chunk: ChunkData): util.Collection[ImageData] = mjpegDecoder.decodeFrames(correlationId, chunk)


}