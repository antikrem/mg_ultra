#include <random>
#include <mutex>

#include "constants.h"
#include "random_ex.h"

//parts of the normal distribution
#define SIGMA_ROOT_TWO_PI(sigma) (sigma * sqrt(2.0f * PI))

std::mutex randLock;

std::default_random_engine rGen;
std::normal_distribution<float> nDist(0.0f, 1.0f);

float rand_ex::next_norm(float mu, float sigma) {
	std::unique_lock<std::mutex> lck(randLock);
	return nDist(rGen) * sigma + mu;
}

void rand_ex::populate_half_norm(int n, float sigma, float* fill) {
	float sum = 0.0f;
	
	for (int i = 0; i < n; i++) {
		fill[i] = INVERSE(SIGMA_ROOT_TWO_PI(sigma)) * exp(-0.5f * SQUARE((float) i / sigma));
		sum += fill[i];
	}

	//ensure all values add to 1 when added as a centered curve
	float offset = (1.0f -  2 * sum + fill[0]) / (float)(2 * n - 1);
	for (int i = 0; i < n; i++) {
		fill[i] += offset;
	}
}