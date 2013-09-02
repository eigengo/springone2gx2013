#include "coins.h"
#include <opencv2/ocl.hpp>

using namespace eigengo::sogx;

bool Point::operator==(const Point& that) const {
	return x == that.x && y == that.y;
}

CoinResult CoinCounter::countCpu(const cv::Mat &image) {
	using namespace cv;
	
	CoinResult result;
	
	Mat dst;
	std::vector<Vec3f> circles;
	
	cvtColor(image, dst, COLOR_RGB2GRAY);
	GaussianBlur(dst, dst, Size(9, 9), 3, 3);
	threshold(dst, dst, 150, 255, THRESH_BINARY);
	GaussianBlur(dst, dst, Size(3, 3), 3, 3);
	HoughCircles(dst, circles, HOUGH_GRADIENT,
				 1,    // dp
				 60,   // min dist
				 200,  // canny1
				 20,   // canny2
				 30,   // min radius
				 100   // max radius
				 );
	
	for (size_t i = 0; i < circles.size(); i++) {
		Coin coin;
		coin.center.x = (int)circles[i][0];
		coin.center.y = (int)circles[i][1];
		coin.radius = (int)circles[i][2];
		result.coins.push_back(coin);
	}
	
#ifdef WITH_RINGS
	int ringCount = 0;
	for (size_t i = 0; i < circles.size(); i++ ) {
		cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
		if (dst.at<uchar>(center) > 0) ringCount++;
	}
	result.hasRing = ringCount > 0;
#endif
	
	return result;
}

// #define WITH_OPENCL

#ifdef WITH_OPENCL
CoinResult CoinCounter::countGpu(const cv::Mat &cpuImage) {
	using namespace cv;

	CoinResult result;
	
	ocl::oclMat image(cpuImage);
	ocl::oclMat dst;
	ocl::oclMat circlesMat;
		
	ocl::cvtColor(image, dst, COLOR_RGB2GRAY);
	ocl::GaussianBlur(dst, dst, Size(9, 9), 3, 3);
	ocl::threshold(dst, dst, 150, 255, THRESH_BINARY);
	ocl::GaussianBlur(dst, dst, Size(3, 3), 3, 3);
	ocl::HoughCircles(dst, circlesMat, HOUGH_GRADIENT,
				 1,    // dp
				 60,   // min dist
				 200,  // canny1
				 19,   // canny2
				 30,   // min radius
				 100   // max radius
				 );
	
	// TODO: Temporary code until OpenCV implements HoughCirclesDownload
	//ocl::HoughCirclesDownload(circlesMat, circles);
	Mat circles;
	if (!circlesMat.empty()) circlesMat.download(circles);
	
	for (size_t i = 0; i < circles.cols; i++) {
		Coin coin;
		coin.center.x = circles.at<float>(0, i * 3 + 0);
		coin.center.y = circles.at<float>(0, i * 3 + 1);
		coin.radius   = circles.at<float>(0, i * 3 + 2);
		
		bool dup = false;
		for (size_t j = 0; j < result.coins.size(); j++) {
			if (result.coins.at(j).center == coin.center ||
				result.coins.at(j).radius == coin.radius) {
				dup = true;
				break;
			}
		}
		if (!dup) result.coins.push_back(coin);
	}
		
	return result;
}
#endif

CoinResult CoinCounter::count(const cv::Mat &image) {
#ifdef WITH_OPENCL
	std::vector<cv::ocl::Info> oclInfo;
	cv::ocl::getDevice(oclInfo);
	return countGpu(image);
#endif
	return countCpu(image);
}
