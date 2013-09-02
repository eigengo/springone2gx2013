package org.eigengo.sogx

import com.fasterxml.jackson.annotation.{JsonProperty, JsonCreator}
import scala.beans.BeanProperty
import java.util

/**
 * Models the coin response with the individual ``coins`` and an indicator of ``success``. As you can see, this is
 * particularly ugly code because of the JSON annotations.
 *
 * @param coins the list of detected coins
 * @param succeeded whether the detection succeeded
 */
case class CoinResponseModel @JsonCreator() (@JsonProperty(value = "coins", required = false) @BeanProperty coins: util.List[CoinModel],
                                             @JsonProperty(value = "succeeded") @BeanProperty succeeded: Boolean)

/**
 * Models the individual coin in the response. Though the class is called coin, it actually represents a circle.
 *
 * @param center the center coordinates
 * @param radius the radius
 */
case class CoinModel @JsonCreator() (@JsonProperty("center") @BeanProperty center: PointModel, @JsonProperty("radius") @BeanProperty radius: Int)

/**
 * Models a point in 2D space
 *
 * @param x the x coordinate
 * @param y the y coordinate
 */
case class PointModel @JsonCreator() (@JsonProperty("x") @BeanProperty x: Int, @JsonProperty("y") @BeanProperty y: Int)
