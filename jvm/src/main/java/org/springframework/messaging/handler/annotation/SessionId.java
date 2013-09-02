package org.springframework.messaging.handler.annotation;

import java.lang.annotation.*;

/**
 * Annotation indicating a method parameter should be bound to the session id of the (web socket) message.
 *
 * @author Jan Machacek
 * @since 4.0
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface SessionId {
}
