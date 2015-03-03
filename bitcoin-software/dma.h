// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#ifndef DMA
#define DMA

#include <stdint.h>
#include "shmac.h"

// Base address of the DMA Slave accelerator:
#define DMA_BASE	((volatile void *) SHMAC_TILE_BASE + 0x4000)

// DMA register names and offsets:
#define DMA_SLAVE_LREG0		0x000
#define DMA_SLAVE_SREG0		0x004
#define DMA_SLAVE_RREG0		0x008
//#define DMA_SLAVE_LREG1		0x00c
//#define DMA_SLAVE_SREG1		0x010
//#define DMA_SLAVE_RREG1		0x014

// SHA256 control register bitnames:
#define DMA_SLAVE_ENABLE	0

// Resets the DMA Module.
void dma_reset(void);

// Retrieves the starting load addresses, storing addresses, and request details (including on/off) from the dma slave.
void dma_get_load_address0(uint8_t * load);
void dma_get_store_address0(uint8_t * store);
void dma_get_request_details0(uint8_t * request);
//void dma_get_load_address1(uint8_t * load);
//void dma_get_store_address1(uint8_t * store);
//void dma_get_request_details1(uint8_t * request);

// Sets the the starting load addresses, storing addresses, and request details (including on/off) from the dma slave.
void dma_set_load_address0(uint8_t * load);
void dma_set_store_address0(uint8_t * store);
void dma_set_request_details0(uint8_t * request);
//void dma_get_load_address1(uint8_t * load);
//void dma_get_store_address1(uint8_t * store);
//void dma_get_request_details1(uint8_t * request);

#endif
