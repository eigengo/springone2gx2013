#include "rtest.h"
#include "coins.h"

using namespace eigengo::sogx;

class RingDetectorTest : public OpenCVTest {
protected:
	CoinCounter coinCounter;
};

#ifdef WITH_RINGS
TEST_F(RingDetectorTest, TwoCoins) {
	auto image = load("coins2.png");
	EXPECT_FALSE(coinCounter.count(image).hasRing);
}

TEST_F(RingDetectorTest, ThreeCoins) {
	auto image = load("coins3.png");
	EXPECT_FALSE(coinCounter.count(image).hasRing);
}

TEST_F(RingDetectorTest, FourCoins) {
	auto image = load("coins4.png");
	EXPECT_FALSE(coinCounter.count(image).hasRing);
}

TEST_F(RingDetectorTest, DamagedFrameWith2Coins) {
	auto image = load("coins2_f1.png");
	EXPECT_FALSE(coinCounter.count(image).hasRing);
}

TEST_F(RingDetectorTest, NoCoins) {
	auto image = load("xb.jpg");
	EXPECT_FALSE(coinCounter.count(image).hasRing);
}

TEST_F(RingDetectorTest, TheOneRing) {
	auto image = load("onering.png");
	EXPECT_TRUE(coinCounter.count(image).hasRing);
}

TEST_F(RingDetectorTest, TheRealOneRing) {
	auto image = load("onering2.png");
	EXPECT_TRUE(coinCounter.count(image).hasRing);
}
#endif