#ifndef SIMPLEAMQPCLIENT_CONFIG_H_
#define SIMPLEAMQPCLIENT_CONFIG_H_

// strerror_s on win32
/* #undef HAVE_STRERROR_S */

// strerror_r on linux
#define HAVE_STRERROR_R


// winsock2.h
/* #undef HAVE_WINSOCK2_H */

// sys/socket.h
#define HAVE_SYS_SOCKET_H

#endif // SIMPLEAMQPCLIENT_CONFIG_H_
