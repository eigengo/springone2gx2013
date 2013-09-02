import Dependencies._

name := "sogx"

organization := "org.eigengo"

version := "1.0"

scalaVersion := "2.10.2"

resolvers ++= Seq(
  "Local Maven Repo"  at "file://" + Path.userHome.absolutePath + "/.m2/repository",
  "Spring Releases"   at "http://repo.springsource.org/release",
  "Spring Milestones" at "http://repo.springsource.org/milestone",
  "Spring Snapshots"  at "http://repo.springsource.org/snapshot"
)

libraryDependencies ++= springframework.all ++ springintegration.all ++ jackson.all ++ reactor.all

libraryDependencies ++= Seq(
  servletApi % "provided",
  specs2     % "test"
)

scalacOptions ++= Seq(
  "-unchecked",
  "-deprecation",
  "-Xlint",
  "-Ywarn-dead-code",
  "-language:_",
  "-target:jvm-1.7",
  "-encoding", "UTF-8"
)

parallelExecution in Test := false

testOptions += Tests.Argument(TestFrameworks.JUnit, "-v")
