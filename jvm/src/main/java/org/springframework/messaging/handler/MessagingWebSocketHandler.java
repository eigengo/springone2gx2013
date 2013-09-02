package org.springframework.messaging.handler;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessageType;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.util.Assert;
import org.springframework.web.socket.*;

import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MessagingWebSocketHandler implements WebSocketHandler, InitializingBean {
    private final Log logger = LogFactory.getLog(MessagingWebSocketHandler.class);

    private boolean ignoreLastNumberPathElement = false;

    private Pattern destinationPattern;

    private final MessageChannel outputChannel;

    public MessagingWebSocketHandler(MessageChannel outputChannel) {
        Assert.notNull(outputChannel, "The 'outputChannel' must not be null.");

        this.outputChannel = outputChannel;
    }

    @Override
    public void afterPropertiesSet() throws Exception {
        if (destinationPattern == null) throw new BeanCreationException("Must set destinationPattern. Set destinationPattern or uriPrefix.");
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        if (logger.isTraceEnabled()) {
            logger.trace("afterConnectionEstablished " + session);
        }
    }

    @Override
    public void handleMessage(WebSocketSession session, WebSocketMessage<?> webSocketMessage) throws Exception {
        try {
            Object payload = null;
            if (webSocketMessage instanceof TextMessage) {
                payload = ((TextMessage)webSocketMessage).getPayload();
            }
            if (webSocketMessage instanceof BinaryMessage) {
                payload = ((BinaryMessage)webSocketMessage).getByteArray();
            }

            // this should not really happen unless there is a new subtype of WebSocketMessage
            if (payload == null) throw new IllegalArgumentException("Unexpected WebSocketMessage type " + webSocketMessage);

            if (logger.isTraceEnabled()) {
                logger.trace("Processing raw webSocketMessage: " + webSocketMessage);
            }

            try {
                RawHeaderAccessor headers = new RawHeaderAccessor(SimpMessageType.MESSAGE);
                Matcher matcher = destinationPattern.matcher(session.getUri().getPath());
                if (matcher.find() && matcher.groupCount() > 0) {
                    headers.setDestination("/" + matcher.group(1));
                }
                headers.setSessionId(session.getId());
                headers.setUser(session.getPrincipal());
                Message<Object> message = MessageBuilder.withPayloadAndHeaders(payload, headers).build();

                outputChannel.send(message);

            }
            catch (Throwable t) {
                logger.error("Terminating STOMP session due to failure to send webSocketMessage: ", t);
                sendErrorMessage(session, t);
            }
        }
        catch (Throwable error) {
            sendErrorMessage(session, error);
        }
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {

    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {

    }

    @Override
    public boolean supportsPartialMessages() {
        return false;
    }

    protected void sendErrorMessage(WebSocketSession session, Throwable error) {
        /* TODO: Implement me
        StompHeaderAccessor headers = StompHeaderAccessor.create(StompCommand.ERROR);
        headers.setMessage(error.getMessage());
        Message<?> message = MessageBuilder.withPayloadAndHeaders(new byte[0], headers).build();
        byte[] bytes = this.stompMessageConverter.fromMessage(message);
        try {
            session.sendMessage(new TextMessage(new String(bytes, Charset.forName("UTF-8"))));
        }
        catch (Throwable t) {
            // ignore
        }
        */
    }

    /**
     * Sets the patterns that extracts the "path" from the raw WS URI. A good example may be <code>/websocket/(.*)/d+</code>
     *
     * This enables you to map the WS requests to <code>@Controller</code>-annotated classes; and to deal with STOMP as
     * well as raw WS messages interchangeably.
     *
     * @param destinationPattern the destinationPattern to be used
     */
    public final void setDestinationPattern(Pattern destinationPattern) {
        Assert.notNull(destinationPattern, "The 'destinationPattern' must not be null.");

        this.destinationPattern = destinationPattern;
    }

    /**
     * Sets the URI prefix that should be dropped from the raw WS URI. This is a more convenient approach than constructing
     * the {@link Pattern} and calling {@link #setDestinationPattern(java.util.regex.Pattern)}.
     *
     * @param uriPrefix the URI prefix to drop
     */
    public final void setUriPrefix(String uriPrefix) {
        String pattern;
        if (this.ignoreLastNumberPathElement) {
            pattern = String.format("%s(.*)/-?\\d+", uriPrefix);
        } else {
            pattern = String.format("%s(.*)", uriPrefix);
        }

        this.destinationPattern = Pattern.compile(pattern);
    }
}

/**
 * Simple implementation of the {@link SimpMessageHeaderAccessor} that handles raw WS messages.
 */
class RawHeaderAccessor extends SimpMessageHeaderAccessor {

    /**
     * Create {@link RawHeaderAccessor} from the headers of an existing {@link org.springframework.messaging.Message}.
     */
    public static RawHeaderAccessor wrap(Message<?> message) {
        return new RawHeaderAccessor(message);
    }

    public RawHeaderAccessor(Message<?> message) {
        super(message);
    }

    protected RawHeaderAccessor(SimpMessageType messageType) {
        super(messageType, Collections.<String, List<String>>emptyMap());
    }

}
