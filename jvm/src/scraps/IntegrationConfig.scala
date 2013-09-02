package org.eigengo.sogx.config

import org.springframework.context.annotation.Bean
import org.springframework.integration.{SpringIntegration, MessageChannel}
import org.springframework.integration.gateway.GatewayProxyFactoryBean
import java.util.concurrent.Executor

trait IntegrationConfig {
  import SpringIntegration.channels._
  import SpringIntegration.gateways._
  import SpringIntegration.messageflow._

  def asyncExecutor(): Executor

  @Bean
  def recogRequest(): MessageChannel = directChannel()

  @Bean
  def recogResponse(): MessageChannel = directChannel()

  @Bean
  def rawRecogResponse(): MessageChannel = directChannel()

  @Bean
  def rawBytesRecogResponse(): MessageChannel = directChannel()

  @Bean
  def recogGateway(): GatewayProxyFactoryBean = {
    gatewayProxy[RecogGateway].
      withMethod(_.recogFrame, requestChannel = recogRequest(), replyChannel = recogResponse()).
      withAsyncExecutor(asyncExecutor())
  }

}
