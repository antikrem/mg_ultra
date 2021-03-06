/*extended random functionality*/
#ifndef __RANDOM_EX__
#define __RANDOM_EX__

namespace rand_ex {

	//gets next normal value
	float next_norm(float mu, float sigma);

	//populates an array X of size N with normal N(mu, sigma);
	void populate_next_norms(float* X, int n, float mu, float sigma);

	//gets next uniform value
	float next_unif(float a, float b);

	//fills an array with results of a normal distribution
	//centered on 0
	//index refers to offset, e.g. values 0-n
	//uniformly increased such that all values add to 1, if offset is true
	void populate_half_norm(int n, float sigma, float* fill, bool applyOffset = true);
}

#endif 