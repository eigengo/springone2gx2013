#ifndef coins_h
#define coins_h

#include <opencv2/opencv.hpp>
#include <vector>
#include <boost/optional.hpp>

namespace eigengo { namespace sogx {

	/**
	 * Simple point in 2D space 
	 */
	struct Point {
		int x;
		int y;
		
		bool operator==(const Point &rhs) const;
	};

	/**
	 * Coin is essentially just a circle on the plane.
	 */
	struct Coin {
		/**
		 * The center of the circle
		 */
		Point center;
		/**
		 * The radius
		 */
		int radius;
	};
	
	/**
	 * Detection result contains a vector of coins, and, if required indicates whether
	 * the scene contains a ring.
	 */
	struct CoinResult {
		/**
		 * All detected coins
		 */
		std::vector<Coin> coins;
#ifdef WITH_RINGS
		/**
		 * Indicates presence of a ring
		 */
		bool hasRing;
#endif
	};
	
	/**
	 * Implements the coin counter on both the CPU as well as the GPU [using OpenCL].
	 */
	class CoinCounter {
	private:
		CoinResult countGpu(const cv::Mat &image);
		CoinResult countCpu(const cv::Mat &image);
	public:
		/**
		 * Counts the coins in the scene represented by ``image``.
		 *
		 * @param the scene
		 * @return the response containing the coins (and, depending on WITH_RINGS detected rings)
		 */
		CoinResult count(const cv::Mat &image);
	};
			
}
}


#endif