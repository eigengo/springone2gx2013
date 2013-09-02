#include "rtest.h"
#include "coins.h"

using namespace eigengo::sogx;

class CoinCounterTest : public OpenCVTest {
protected:
	CoinCounter counter;
};

TEST_F(CoinCounterTest, TwoCoins) {
	auto image = load("coins2.png");
	EXPECT_EQ(2, counter.count(image).coins.size());
}

TEST_F(CoinCounterTest, ThreeCoins) {
	auto image = load("coins3.png");
	EXPECT_EQ(3, counter.count(image).coins.size());
}

TEST_F(CoinCounterTest, FourCoins) {
	auto image = load("coins4.png");
	EXPECT_EQ(4, counter.count(image).coins.size());
}

TEST_F(CoinCounterTest, DamagedFrameWith2Coins) {
	auto image = load("coins2_f1.png");
	EXPECT_EQ(2, counter.count(image).coins.size());
}

TEST_F(CoinCounterTest, NoCoins) {
	auto image = load("xb.jpg");
	EXPECT_EQ(0, counter.count(image).coins.size());
}
