#ifndef __BLETXRX_H
#define __BLETXRX_H

#include <stdbool.h>
#include <stdint.h>

#include "tuning.h"
#include "ble.h"

// BLE transceiver demo

void debounce_gpio(unsigned short gpio, unsigned short* gpio_out,
                   unsigned int* trans_out);
// delays
static inline void delay_cycles(volatile uint32_t count);
// load advertisement packet
static inline void ble_adv_packet(void);
// load scan response packet
static inline void ble_scan_rsp_packet(void);
// load packet into fifo
static inline void ble_load_fifo_fast(bool mode);
// transmit from fifo
static inline void ble_tx_fifo(void);
// full demo
void ble_connect_init(void);
void ble_fake_connnect();
void ble_fast_connect(int cycles);

#endif