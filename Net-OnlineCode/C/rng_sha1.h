// Random Number generation based on SHA1

#ifndef RNG_SHA1_H
#define RNG_SHA1_H

#include <stdint.h>
#include <openssl/sha.h>

#define OC_RNG_BITS 160
#define OC_RNG_BYTES 20

// file to read random byte from (assumes Unix-like system)
#define OC_RANDOM_SOURCE "/dev/urandom"

typedef struct {

  char seed[OC_RNG_BYTES];
  char current[OC_RNG_BYTES];
  
  int reserved; // possible internal use
} oc_rng_sha1;



void oc_rng_init(oc_rng_sha1 *rng);
void oc_rng_init_seed(oc_rng_sha1 *rng, const char *seed);
void oc_rng_init_random(oc_rng_sha1 *rng);

int oc_rng_random_uuid(char *dest);

float oc_rng_rand(oc_rng_sha1 *rng, float max);

void oc_rng_advance(oc_rng_sha1 *rng);



#endif
