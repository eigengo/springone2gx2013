import sbt._

object Dependencies {
  object springframework {
    private val version   = "4.0.0.BUILD-SNAPSHOT"  //3.2.4.RELEASE

    def dep(artifact: String) = "org.springframework" % artifact % version

    val context   = dep("spring-context")
    val tx        = dep("spring-tx")
    val webmvc    = dep("spring-webmvc")
    val websocket = dep("spring-websocket")
    val messaging = dep("spring-messaging")

    val headless = Seq(context, tx, messaging)
    val web      = Seq(webmvc, websocket)

    val all      = headless ++ web
  }

  object springintegration {
    private val version = "3.0.0.BUILD-SNAPSHOT"  //2.2.4.RELEASE

    def dep(artifact: String) = "org.springframework.integration" % artifact % version

    val core   = dep("spring-integration-core") exclude("org.springframework", "spring-tx")
    val amqp   = dep("spring-integration-amqp") exclude("org.springframework", "spring-tx")
    val stream = dep("spring-integration-stream") exclude("org.springframework", "spring-tx")

    val all = Seq(core, amqp, stream)
  }

  object jackson {
    private val version = "2.2.2"
    //val scalaModule = "com.fasterxml.jackson.module" %% "jackson-module-scala" % version
    val core        = "com.fasterxml.jackson.core"    % "jackson-databind"     % version

    val all = Seq(core)
  }

  object reactor {
    private val version = "1.0.0.M1"

    val core   = "org.projectreactor" % "reactor-core" % version
    val tcp    = "org.projectreactor" % "reactor-tcp"  % version

    val all = Seq(core, tcp)
  }

  // to help resolve transitive problems, type:
  //   `sbt dependency-graph`
  //   `sbt test:dependency-tree`
  val bad = Seq(
    ExclusionRule(name = "log4j"),
    ExclusionRule(name = "commons-logging"),
    ExclusionRule(name = "commons-collections"),
    ExclusionRule(organization = "org.slf4j")
  )

  val xuggler       = "xuggle"                % "xuggle-xuggler"     % "5.4"
  val servletApi    = "javax.servlet"         % "javax.servlet-api"  % "3.1.0"
  val specs2        = "org.specs2"           %% "specs2"             % "2.0"
}
