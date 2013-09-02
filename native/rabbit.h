#ifndef rabbit_h
#define rabbit_h

#include <iostream>
#include <fstream>
#include <algorithm>
#include <iterator>
#include <vector>
#include <amqp.h>
#include <SimpleAmqpClient/SimpleAmqpClient.h>

namespace eigengo { namespace sogx {

	/**
	 * Superclass for all RabbitMQ server components that attach to a queue, receive messages, perform some
	 * processing and reply with a std::string.
	 */
	class RabbitRpcServer {
	private:
		std::string queue;
		std::string exchange;
		std::string routingKey;
		
		void runBlocking();
	protected:
		/**
		 * Override this method to handle the incoming envelope. The default implementation here extracts the payload
		 * and calls ``handleMessage()``, but your override can perform any other action. The implementation must be
		 * stateless.
		 *
		 * @param envelope the received envelope
		 * @param the channel the message arrived on
		 */
		virtual void handleEnvelope(const AmqpClient::Envelope::ptr_t envelope, const AmqpClient::Channel::ptr_t channel);

		/**
		 * Implement this method to handle the incoming message. The implementation must be stateless
		 *
		 * @param message the incoming message
		 * @param channel the channel the message arrived on
		 */
		virtual std::string handleMessage(const AmqpClient::BasicMessage::ptr_t message, const AmqpClient::Channel::ptr_t channel) = 0;

		/**
		 * Perform some custom initialization in a thread; this method will be called once for every thread that
		 * is created in the client.
		 */
		virtual void inThreadInit();
	public:

		/**
		 * Constructs the instance of the ``RabbitRpcServer`` attaching to the given ``queue``,
		 * on the ``exchange`` and ``routingKey``
		 *
		 * @param queue the queue name; the queue must exist
		 * @param exchange the exchange name; the exchange must exist
		 * @param routingKey the routing key for the queue on the exchange
		 */
		RabbitRpcServer(const std::string queue, const std::string exchange, const std::string routingKey);

		/**
		 * Default destructor
		 */
		virtual ~RabbitRpcServer();
		
		/**
		 * Receives the messsages from the AMQP broker using the specified number of threads; performs the 
		 * ``handleEnvelope`` and--in the default implementation--``handleMessage`` on the messages. 
		 * Nota bene that the ``handle*`` methods are being executed on this instance, but from multiple threads,
		 * unless you specify ``threadCount = 1``.
		 *
		 * @param threadCount the number of threads
		 */
		void runAndJoin(const int threadCount);
	};
	
} }

#endif
