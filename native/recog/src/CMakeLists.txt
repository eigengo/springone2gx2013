set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/..)

add_executable(recog main.cpp coins.cpp ../../../jzon.cpp ../../../rabbit.cpp ../../../im.cpp)
target_link_libraries(recog ${Rabbitmqc_LIBRARY} ${Boost_LIBRARIES} ${SimpleAmqpClient_LIBRARY} ${OpenCV_LIBS})

add_executable(recogr main.cpp coins.cpp ../../../jzon.cpp ../../../rabbit.cpp ../../../im.cpp)
target_link_libraries(recogr ${Rabbitmqc_LIBRARY} ${Boost_LIBRARIES} ${SimpleAmqpClient_LIBRARY} ${OpenCV_LIBS})
set_property(TARGET recogr APPEND PROPERTY COMPILE_DEFINITIONS WITH_RINGS)
