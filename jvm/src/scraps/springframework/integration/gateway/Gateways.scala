package org.springframework.integration.gateway

import scala.reflect.ClassTag

trait Gateways {

  def gatewayProxy[A : ClassTag]: GatewayProxyFactoryBeanBuilder[A] = {
    GatewayProxyFactoryBeanBuilder[A](implicitly[ClassTag[A]])
  }

}
