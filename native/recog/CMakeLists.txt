cmake_minimum_required (VERSION 2.8) 
project (recog) 

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/Modules)
set(CMAKE_CXX_FLAGS "-std=c++11 -stdlib=libc++")
add_definitions("-std=c++11")
enable_testing()

find_package(Boost REQUIRED COMPONENTS system chrono thread)
find_package(Rabbitmqc REQUIRED)
find_package(SimpleAmqpClient REQUIRED)
find_package(OpenCV 2.4.7 REQUIRED)

set(OpenCV_LIBS "opencv_gpu;opencv_contrib;opencv_legacy;opencv_objdetect;opencv_features2d;opencv_ml;opencv_imgproc;opencv_highgui;opencv_core;opencv_ocl")
include_directories(${recog_SOURCE_DIR}/src)
include_directories(SYSTEM ${Rabbitmqc_INCLUDE_DIRS})
include_directories(SYSTEM ${SimpleAmqpClient_INCLUDE_DIRS})
include_directories(..)
include_directories(${Boost_INCLUDE_DIRS})
link_directories(${Boost_LIBRARY_DIRS})

add_subdirectory(src)

########## GTest ##########
set(GTEST_ROOT "${PROJECT_SOURCE_DIR}/../gtest-1.6.0")
add_subdirectory("${PROJECT_SOURCE_DIR}/../gtest-1.6.0" "${CMAKE_CURRENT_BINARY_DIR}/gtest")
add_subdirectory(test)

add_test(recog-test test/recog-test)