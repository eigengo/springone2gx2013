package org.eigengo.sogx.config

import org.springframework.context.annotation.{Bean, Configuration, ComponentScan}
import org.springframework.web.servlet.config.annotation.{DefaultServletHandlerConfigurer, WebMvcConfigurerAdapter, EnableWebMvc}
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor
import org.eigengo.sogx._
import org.springframework.integration.annotation.{Payload, Header}

