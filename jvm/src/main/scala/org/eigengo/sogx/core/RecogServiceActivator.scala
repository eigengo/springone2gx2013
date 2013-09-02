package org.eigengo.sogx.core

import org.eigengo.sogx._
import org.springframework.integration.annotation.{Payload, Header}

trait RecogServiceActivator {

  def onCoinResponse(@Header correlationId: CorrelationId, coins: CoinResponse): Unit

}