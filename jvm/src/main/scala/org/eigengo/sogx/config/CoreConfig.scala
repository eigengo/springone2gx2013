package org.eigengo.sogx.config

import org.springframework.messaging.support.channel.ExecutorSubscribableChannel
import org.springframework.context.annotation.Bean
import org.springframework.messaging.simp.{SimpMessagingTemplate, SimpMessageSendingOperations}
import org.springframework.messaging.support.converter.MappingJackson2MessageConverter
import org.eigengo.sogx.core._
import java.util.concurrent.Executor
import org.springframework.integration.channel.DirectChannel

/**
 * Contains beans that make up the core of the application. It includes the the "headless" components that do not
 * require nor rely on any user interface. When mixed-in, the beans in this trait can be used in command-line apps,
 * web apps, or anything else you may want to create.
 *
 * The boring components are the ``mjpegDecoder``, ``chunkDecoder``, ``recogService``, and ``recogSession``.
 * In addition to the four boring components, we have the components that the implementations must provide. They are the
 * ``asyncExecutor`` and ``recogServiceActivator``. The ``asyncExecutor`` defines the way in which the ``dispatchChannel``
 * is going to route the messages around. The more interesting component is ``recogServiceActivator``, which defines
 * what happens to the recog messages when they arrive from the nether world of the native code.
 *
 * Finally, we have a little bit of Spring Integration, defining the ``recogChannel`` (which is used
 * in the Spring Integration configuration that's hiding in ``/META-INF/spring/integration/module-context.xml``),
 * and the ``dispatchChannel`` that is ultimately used by the Spring Messaging code to deliver the messages that arrive
 * on it over the web sockets.
 */
trait CoreConfig {

  // -- The boring components

  // Decodes incoming MJPEG chunks into frames that can be sent to RMQ
  @Bean def mjpegDecoder() = new MJPEGDecoder()

  // Decodes incoming chunks into frames that can be sent to RMQ
  @Bean def chunkDecoder() = new ChunkDecoder(mjpegDecoder())

  // Recog service is a gateway to the recognition flow
  @Bean def recogService(): RecogService = new RecogService(recogRequest())

  // maintains the recognition sessions
  @Bean def recogSessions() = new RecogSessions(dispatchMessagingTemplate())

  // -- The additional components that the core depends on

  // implementations must provide appropriate Executor
  @Bean def asyncExecutor(): Executor

  // implementations must provide RecogServiceActivator, which will be executed when we have the coins from the
  // video frames
  @Bean def recogServiceActivator(): RecogServiceActivator

  // -- The integration plumbing

  // the channel onto which the requests will go
  @Bean def recogRequest() = new DirectChannel()

  // the message converter for the payloads
  @Bean def messageConverter() = new DelegatingJsonMessageConverter(new MappingJackson2MessageConverter())

  // the channel that connects to the WS clients
  @Bean def dispatchChannel() = new ExecutorSubscribableChannel(asyncExecutor())

  // MessagingTemplate (and MessageChannel) to dispatch messages to for further processing
  // All MessageHandler beans above subscribe to this channel
  @Bean def dispatchMessagingTemplate(): SimpMessageSendingOperations = {
    val template = new SimpMessagingTemplate(dispatchChannel())
    template.setMessageConverter(messageConverter())
    template
  }

}
