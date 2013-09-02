package org.eigengo.sogx.core

import org.springframework.messaging.support.converter.MessageConverter
import org.springframework.messaging.support.MessageBuilder
import org.springframework.messaging.Message
import java.lang.reflect.Type

/**
 * The ``MappingJackson2MessageConverter`` allows non-object and non-array root JSON entities, which is not quite right.
 * This converter modifies its behaviour so that [at least] ``String``s are taken as literal JSON values and not
 * converted any further.
 *
 * All other messages get passed to the ``otherConverter`` for processnig.
 *
 * @param otherConverter the converter for the complicated types
 */
class DelegatingJsonMessageConverter(otherConverter: MessageConverter[Object]) extends MessageConverter[Object] {

  private def toMessage0(payload: Object): Message[_] = payload match {
    case s: String                  => MessageBuilder.withPayload(s.getBytes).build()
    case x                          => otherConverter.toMessage(x)
  }

  // The implementation is particularly ugly here (viz ``asInstanceOf[...]``), because Message[A] is not
  // covariant in its type parameter. That's the ugly side of Java / Scala interop.
  def toMessage[P](payload: Object): Message[P] = toMessage0(payload).asInstanceOf[Message[P]]

  // Again, rather ugly, because ``_`` in Scala means any type, including primitives. In the Java world,
  // ``?`` means ``Object``, hence the cast to ``Object``.
  def fromMessage(message: Message[_], targetClass: Type): Object = message.getPayload.asInstanceOf[Object]

}
