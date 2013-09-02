package org.springframework.integration.gateway

import java.util.concurrent.Executor
import scala.reflect.ClassTag
import org.springframework.integration.MessageChannel

case class GatewayProxyFactoryBeanBuilder[A](serviceInterface: ClassTag[A], executor: Option[Executor] = None) {

  def withAsyncExecutor(executor: Executor): GatewayProxyFactoryBeanBuilder[A] = {
    copy(executor = Some(executor))
  }

  def withMethod[U, A1](method: A => (A1) => U, requestChannel: MessageChannel = null, replyChannel: MessageChannel = null,
                                                requestTimeout: Long = Long.MinValue, replyTimeout: Long = Long.MinValue): GatewayProxyFactoryBeanBuilder[A] = {
    this
  }

  private def build(): GatewayProxyFactoryBean = {
    val gatewayProxyFactoryBean = new GatewayProxyFactoryBean()
    gatewayProxyFactoryBean.setServiceInterface(serviceInterface.runtimeClass)
    executor.map(gatewayProxyFactoryBean.setAsyncExecutor)
    gatewayProxyFactoryBean
  }
}

object GatewayProxyFactoryBeanBuilder {

  implicit def toGatewayProxyFactoryBean(builder: GatewayProxyFactoryBeanBuilder[_]) = {
    builder.build()
  }

}
