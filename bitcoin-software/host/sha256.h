// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef SHA256_H
#define SHA256_H

#include <stdint.h>

struct sha256_context;

// Creates a new SHA256 context:
struct sha256_context * sha256_new(void);
// Frees a SHA256 context:
void sha256_free(struct sha256_context *);

// Resets a SHA256 context:
void sha256_reset(struct sha256_context * ctx);

// Hash a block of data:
void sha256_hash_block(struct sha256_context * ctx, const uint32_t * data);

// Pad a block of data to hash:
void sha256_pad_le_block(uint8_t * block, int block_length, uint64_t total_length);

// Get the hash from a SHA256 context:
void sha256_get_hash(const struct sha256_context * ctx, uint8_t * hash);

// Formats a hash for printing:
void sha256_format_hash(const uint8_t * hash, char * output);

#endif

