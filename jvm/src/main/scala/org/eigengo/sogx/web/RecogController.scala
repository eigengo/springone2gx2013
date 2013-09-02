package org.eigengo.sogx.web

import org.springframework.stereotype.Controller
import org.springframework.web.bind.annotation._
import org.springframework.beans.factory.annotation.Autowired
import org.eigengo.sogx._
import java.util.UUID
import org.springframework.messaging.handler.annotation.{SessionId, MessageBody, MessageMapping}
import org.eigengo.sogx.core.{RecogService, RecogSessions}

/**
 * The recognition service controller that handles both boring-old HTTP requests as well as incoming WS requests.
 * The Spring Messaging infrastructure allows us to map both mechanisms onto the ``@*Mapping``-annotated methods.
 *
 * We have ``@MessageMapping``-annotated methods that handle the incoming raw WebSocket messages that process
 * the image and mjpeg chunks.
 *
 * To demonstrate that this is indeed still old-school ``@Controller`` working in the ``DispatcherServlet`` world,
 * and to have a backup for the demo, we have here two ``@RequestMapping``-annotated methods that submit the well-known
 * image and MJPEG stream.
 *
 * This class delegates the hard work of processing the requests to the ``RecogService`` and ``RecogSessions``.
 *
 * @param recogService the [injected] instance of the ``RecogService``
 * @param recogSessions the [injected] instance of the ``RecogSessions``
 */
@Controller
class RecogController @Autowired()(recogService: RecogService, recogSessions: RecogSessions) {

  /*
    Following two methods are called when a WebSocket message arrives. The WebSocket sessionId is
    extracted and passed as the parameter of the method.

    Notice that the type of the ``sessionId`` parameter is ``RecogSessionId``, and yet the
    ``SessionIdMethodArgumentResolver`` can deal with this seemingly custom type naively, without
    any complex conversions. This is because ``RecogSessionId`` extends ``AnyVal``, and thus it
    appears as the type of the "boxed" type in ``RecogSessionId``, which is ``String``!

    Also notice that we apply the ``imageChunk`` and ``mjpegChunk`` functions to both their parameter
    lists.
   */
  @MessageMapping(Array("/app/recog/image"))
  def image(@SessionId sessionId: RecogSessionId, @MessageBody body: ChunkData): Unit = {
    recogService.imageChunk(sessionId.value)(body)
  }

  @MessageMapping(Array("/app/recog/mjpeg"))
  def mjpeg(@SessionId sessionId: RecogSessionId, @MessageBody body: ChunkData): Unit = {
    recogService.mjpegChunk(sessionId.value)(body)
  }

  /*
    Following two methods are for our debugging and demo purposes. They use the [absolutely horrible]
    ``Utils.reader`` object functions to read blocks of well-known files (coins2.png) and (coins2.mjpeg)
    and submit them to the ``recogService``.

    Because the ``readAll`` and ``readChunk`` functions block, when they complete, we can safely call the
    recog session as ended. Hence the call to ``recogSessions.sessionEnded``.
   */

  @RequestMapping(Array("/app/predef/image"))
  @ResponseBody
  def foo(): String = {
    val id = UUID.randomUUID().toString
    Utils.reader.readAll("/coins2.png")(recogService.imageChunk(id))
    recogSessions.sessionEnded(RecogSessionId(id))
    "image"
  }

  @RequestMapping(Array("/app/predef/coins"))
  @ResponseBody
  def bar(@RequestParam(defaultValue = "10") fps: Int): String = {
    val id = UUID.randomUUID().toString
    Utils.reader.readChunks("/coins2.mjpeg", fps)(recogService.mjpegChunk(id))
    recogSessions.sessionEnded(RecogSessionId(id))
    "coins"
  }

}
