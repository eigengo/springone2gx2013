package org.springframework.messaging.handler.annotation.support;

import org.springframework.core.MethodParameter;
import org.springframework.messaging.Message;
import org.springframework.messaging.handler.annotation.SessionId;
import org.springframework.messaging.handler.method.HandlerMethodArgumentResolver;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;

public class SessionIdMehtodArgumentResolver implements HandlerMethodArgumentResolver {

    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        return parameter.hasParameterAnnotation(SessionId.class);
    }

    @Override
    public Object resolveArgument(MethodParameter parameter, Message<?> message) throws Exception {
        SessionId annot = parameter.getParameterAnnotation(SessionId.class);
        if (annot == null) return null;
        if (!message.getHeaders().containsKey(SimpMessageHeaderAccessor.SESSION_ID_HEADER)) return null;

        // we have the parameter
        Object sessionId =  message.getHeaders().get(SimpMessageHeaderAccessor.SESSION_ID_HEADER);
        if (sessionId == null) return null;

        Class<?> sourceClass = sessionId.getClass();
        Class<?> targetClass = parameter.getParameterType();
        if (targetClass.isAssignableFrom(sourceClass)) {
            return sessionId;
        }

        return null;
    }
}
