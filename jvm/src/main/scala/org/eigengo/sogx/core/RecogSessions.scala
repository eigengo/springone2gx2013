package org.eigengo.sogx.core

import org.springframework.messaging.simp.SimpMessageSendingOperations
import java.util
import org.eigengo.sogx._

/**
 * Holds the current recognition sessions in a crude in-memory HashMap. Whenever a coin response is received,
 * we put it in the session store and fire a message to the ``/topic/recog/sessions`` topic with the entire
 * session store. This allows applications that have subscribed to the topic to display all sessions at once.
 *
 * When a session ends (typically when the iOS app closes the socket), we remove the just ended session and
 * send a message on the ``/topic/recog/sessions`` so that the subscribers can update their state.
 *
 * @param messageSender the message sender that delivers the topic messages
 */
class RecogSessions(messageSender: SimpMessageSendingOperations) {
  val sessions = new util.HashMap[RecogSessionId, CoinResponse]()

  /**
   * Called when a coin response is received on the given ``correlationId``.
   *
   * @param correlationId the correlation id for the responses
   * @param coins the actual coins
   */
  def onCoinResponse(correlationId: CorrelationId, coins: CoinResponse): Unit = {
    sessions.put(RecogSessionId(correlationId.value), coins)
    sendSessions()
  }

  /**
   * Called when the recognition session ends.
   *
   * @param sessionId the identifier of the session that has just ended
   */
  def sessionEnded(sessionId: RecogSessionId): Unit = {
    sessions.remove(sessionId)
    sendSessions()
  }

  private def sendSessions(): Unit = messageSender.convertAndSend("/topic/recog/sessions", sessions.values())

}
