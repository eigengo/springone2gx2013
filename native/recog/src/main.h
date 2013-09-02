#ifndef main_h
#define main_h

#include <inttypes.h>
#include "rabbit.h"
#include "coins.h"

namespace eigengo { namespace sogx {
	
	class Main : public RabbitRpcServer {
	private:
		CoinCounter coinCounter;
	protected:
		virtual std::string handleMessage(const AmqpClient::BasicMessage::ptr_t message, const AmqpClient::Channel::ptr_t channel);
	public:
		Main(const std::string queue, const std::string exchange, const std::string routingKey);
	};
  
} }
#endif
