package org.springframework.integration

import org.springframework.integration.channel.DirectChannel

trait Channels {

  def directChannel(): MessageChannel = new DirectChannel()

}
