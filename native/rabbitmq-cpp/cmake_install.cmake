# Install script for directory: /Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp

# Set the install prefix
IF(NOT DEFINED CMAKE_INSTALL_PREFIX)
  SET(CMAKE_INSTALL_PREFIX "/usr/local")
ENDIF(NOT DEFINED CMAKE_INSTALL_PREFIX)
STRING(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
IF(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  IF(BUILD_TYPE)
    STRING(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  ELSE(BUILD_TYPE)
    SET(CMAKE_INSTALL_CONFIG_NAME "Release")
  ENDIF(BUILD_TYPE)
  MESSAGE(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
ENDIF(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)

# Set the component getting installed.
IF(NOT CMAKE_INSTALL_COMPONENT)
  IF(COMPONENT)
    MESSAGE(STATUS "Install component: \"${COMPONENT}\"")
    SET(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  ELSE(COMPONENT)
    SET(CMAKE_INSTALL_COMPONENT)
  ENDIF(COMPONENT)
ENDIF(NOT CMAKE_INSTALL_COMPONENT)

IF(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  FILE(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib" TYPE STATIC_LIBRARY FILES "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/libSimpleAmqpClient.a")
  IF(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libSimpleAmqpClient.a" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libSimpleAmqpClient.a")
    EXECUTE_PROCESS(COMMAND "/usr/bin/ranlib" "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/libSimpleAmqpClient.a")
  ENDIF()
ENDIF(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")

IF(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")
  FILE(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/include/SimpleAmqpClient" TYPE FILE FILES
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/SimpleAmqpClient.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/AmqpException.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/Channel.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/BasicMessage.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/Util.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/AmqpResponseLibraryException.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/ConnectionClosedException.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/ConsumerTagNotFoundException.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/Envelope.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/MessageReturnedException.h"
    "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/src/SimpleAmqpClient/Table.h"
    )
ENDIF(NOT CMAKE_INSTALL_COMPONENT OR "${CMAKE_INSTALL_COMPONENT}" STREQUAL "Unspecified")

IF(CMAKE_INSTALL_COMPONENT)
  SET(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
ELSE(CMAKE_INSTALL_COMPONENT)
  SET(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
ENDIF(CMAKE_INSTALL_COMPONENT)

FILE(WRITE "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/${CMAKE_INSTALL_MANIFEST}" "")
FOREACH(file ${CMAKE_INSTALL_MANIFEST_FILES})
  FILE(APPEND "/Users/janmachacek/Talks/springone2gx2013/native/rabbitmq-cpp/${CMAKE_INSTALL_MANIFEST}" "${file}\n")
ENDFOREACH(file)
