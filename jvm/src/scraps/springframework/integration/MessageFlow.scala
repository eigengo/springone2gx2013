package org.springframework.integration

trait MessageFlow {

  type Id[A] = A

  def messageFlow[In, Out, M[_]]: In => M[Out] = ???

}
