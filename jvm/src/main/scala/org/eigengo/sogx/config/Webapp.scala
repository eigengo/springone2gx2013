package org.eigengo.sogx.config

import org.springframework.context.annotation.{Bean, Configuration, ComponentScan}
import org.springframework.web.servlet.config.annotation.{DefaultServletHandlerConfigurer, WebMvcConfigurerAdapter, EnableWebMvc}
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor
import org.eigengo.sogx._
import org.springframework.integration.annotation.{Payload, Header}
import org.eigengo.sogx.core.RecogServiceActivator

@Configuration
@EnableWebMvc
@ComponentScan(basePackages=Array("org.eigengo.sogx"))
class Webapp extends WebMvcConfigurerAdapter with WebConfig with CoreConfig {

  @Bean def asyncExecutor() = {
    val executor = new ThreadPoolTaskExecutor
    executor.setCorePoolSize(4)
    executor.setCorePoolSize(8)
    executor.setThreadNamePrefix("MessageChannel-")
    executor
  }

  @Bean def recogServiceActivator() = new RecogServiceActivator {
    def onCoinResponse(@Header correlationId: CorrelationId, @Payload coins: CoinResponse): Unit =
      recogSessions().onCoinResponse(correlationId, coins)
  }

  // Allow serving HTML files through the default Servlet
  override def configureDefaultServletHandling(configurer: DefaultServletHandlerConfigurer) = {
    configurer.enable()
  }

}
