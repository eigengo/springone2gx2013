package org.eigengo.sogx.config

import javax.servlet.ServletRegistration
import org.springframework.web.servlet.support.AbstractAnnotationConfigDispatcherServletInitializer

class DispatcherServletInitializer extends AbstractAnnotationConfigDispatcherServletInitializer {

  protected def getRootConfigClasses: Array[Class[_]] = {
    Array[Class[_]](classOf[Webapp])
  }

  protected def getServletConfigClasses: Array[Class[_]] = {
    Array[Class[_]](classOf[Webapp])
  }

  protected def getServletMappings: Array[String] = {
    Array[String]("/")
  }

  protected override def customizeRegistration(registration: ServletRegistration.Dynamic) {
    registration.setInitParameter("dispatchOptionsRequest", "true")
  }

}
