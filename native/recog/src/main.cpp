#include "main.h"
#include "im.h"
#include "jzon.h"

using namespace eigengo::sogx;

Main::Main(const std::string queue, const std::string exchange, const std::string routingKey) :
RabbitRpcServer::RabbitRpcServer(queue, exchange, routingKey) {
	
}

std::string Main::handleMessage(const AmqpClient::BasicMessage::ptr_t message, const AmqpClient::Channel::ptr_t channel) {
	Jzon::Object responseJson;
	try {
		// get the message, read the image
		ImageMessage imageMessage(message);
		auto imageData = imageMessage.headImage();
		auto imageMat = cv::imdecode(cv::Mat(imageData), 1);

		// ponies & unicorns
		Jzon::Array coinsJson;
		auto result = coinCounter.count(imageMat);
		for (auto i = result.coins.begin(); i != result.coins.end(); ++i) {
			Jzon::Object coinJson;
			Jzon::Object centerJson;
			centerJson.Add("x", i->center.x);
			centerJson.Add("y", i->center.y);
			coinJson.Add("center", centerJson);
			coinJson.Add("radius", i->radius);
			coinsJson.Add(coinJson);
		}
#ifdef WITH_RINGS
		responseJson.Add("hasRing", result.hasRing);
#endif		
		responseJson.Add("coins", coinsJson);
		responseJson.Add("succeeded", true);
	} catch (std::exception &e) {
		// bantha poodoo!
		std::cerr << e.what() << std::endl;
		responseJson.Add("succeeded", false);
	} catch (...) {
		// more bantha fodder!
		responseJson.Add("succeeded", false);
	}

#ifdef DEBUG
	std::cout << message->ReplyTo() << std::endl;
#endif
	Jzon::Writer writer(responseJson, Jzon::NoFormat);
	writer.Write();

	return writer.GetResult();
}

int main(int argc, char** argv) {
	Main main("sogx.recog.queue", "sogx.exchange", "sogx.recog.key");
	main.runAndJoin(8);
	return 0;
}