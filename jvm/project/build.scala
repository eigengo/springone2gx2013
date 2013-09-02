/*
import sbt._
import Keys._
import net.virtualvoid.sbt.graph.Plugin._
import org.scalastyle.sbt._

// to sync this project with IntelliJ, run the sbt-idea plugin with: sbt gen-idea
//
// to set user-specific local properties, just create "~/.sbt/my-settings.sbt", e.g.
// javaOptions += "some cool stuff"
//
// This project allows a local.conf on the classpath (e.g. domain/src/main/resources) to override settings, e.g.
//
// mkdir -p {$MODULE}/src/{main,test}/{java,scala,resources}/com/eigengo/castor
//
// the following were useful for writing this file
// http://www.scala-sbt.org/release/docs/Getting-Started/Multi-Project.html
// https://github.com/sbt/sbt/blob/0.12.2/main/Build.scala
// https://github.com/akka/akka/blob/master/project/AkkaBuild.scala
object SpringOne2GXBuild extends Build {

  override val settings = super.settings ++ Seq(
    organization := "org.eigengo.sogx",
    version := "1.0-SNAPSHOT",
    scalaVersion := "2.10.2"
  )

  lazy val defaultSettings = Defaults.defaultSettings ++ graphSettings ++ Seq(
    scalacOptions in Compile ++= Seq("-encoding", "UTF-8", "-target:jvm-1.7", "-deprecation", "-unchecked"),
    javacOptions in Compile ++= Seq("-source", "1.8", "-target", "1.7", "-Xlint:unchecked", "-Xlint:deprecation", "-Xlint:-options"),
    // https://github.com/sbt/sbt/issues/702
    javaOptions += "-Djava.util.logging.config.file=logging.properties",
    javaOptions += "-Xmx2G",
    outputStrategy := Some(StdoutOutput),
    fork := true,
    maxErrors := 1,
    resolvers ++= Seq(
      Resolver.mavenLocal,
      Resolver.sonatypeRepo("releases"),
      Resolver.typesafeRepo("releases"),
      Resolver.typesafeRepo("snapshots"),
      Resolver.sonatypeRepo("snapshots"),
      "SpringSource Releases" at "http://repo.springsource.org/release",
      "SpringSource Milestones" at "http://repo.springsource.org/milestone"
    ),
    parallelExecution in Test := false
  ) ++ ScalastylePlugin.Settings

  def module(dir: String) = Project(id = dir, base = file(dir), settings = defaultSettings)
  import Dependencies._

  lazy val core = module("core") settings(
    libraryDependencies ++= springframework.headless,
    libraryDependencies ++= springintegration.all,
    libraryDependencies ++= jackson.all,
    libraryDependencies +=  specs2 % "test"
  )
  lazy val cli = module("cli") dependsOn(core) settings(
  )
  lazy val web = module("web") dependsOn(core) settings(
    libraryDependencies ++= springframework.web,
    libraryDependencies ++= reactor.all,
    libraryDependencies +=  servletApi % "provided",
    libraryDependencies +=  specs2 % "test"
  )
  lazy val root = Project(id = "parent", base = file("."), settings = defaultSettings) settings (
    mainClass in (Compile, run) := Some("org.eigengo.springone2gx.main.Main")
  ) aggregate (
    core, cli, web
  ) dependsOn web // yuck
}

*/