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

}
