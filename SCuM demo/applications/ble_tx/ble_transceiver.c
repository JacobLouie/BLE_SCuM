#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "memory_map.h"
#include "radio.h"
#include "scm3c_hw_interface.h"
#include "tuning.h"
#include "ble.h"
#include "ble_transceiver.h"

// BLE transceiver demo
//===================================================================================
typedef struct {
    uint8_t packet[BLE_MAX_PACKET_LENGTH];
		uint8_t data[BLE_CUSTOM_DATA_LENGTH];
} ble_short_t;

ble_short_t ble_adv, ble_rsp;

// GPIO debounce
typedef struct gpio_tran_t {
    unsigned short gpio;
    unsigned int timestamp_tran;
} gpio_tran_t;

void debounce_gpio(unsigned short gpio, unsigned short* gpio_out,
                   unsigned int* trans_out) {
    // keep track of number of times this gpio state has been measured since
    // most recent transistion
    static int count;
    static gpio_tran_t deb_gpio;  // current debounced state

    static unsigned int tran_time;
    static unsigned short target_state;
    // two states: debouncing and not debouncing
    static enum state {
        NOT_DEBOUNCING = 0,
        DEBOUNCING = 1
    } state = NOT_DEBOUNCING;

    switch (state) {
        case NOT_DEBOUNCING: {
            // if not debouncing, compare current gpio state to previous
            // debounced gpio state
            if (gpio != deb_gpio.gpio) {
                // record start time of this transition
                tran_time = RFTIMER_REG__COUNTER;
                // if different, initiate debounce procedure
                state = DEBOUNCING;
                target_state = gpio;

                // increment counter for averaging
                count++;
            }
            // otherwise just break without changing curr_state
            break;
        }
        case DEBOUNCING: {
            // if debouncing, compare current gpio state to target transition
            // state
            if (gpio == target_state) {
                // if same as target transition state, increment counter
                count++;
            } else {
                // if different from target transition state, decrement counter
                count--;
            }

            // if count is high enough
            if (count >= 1) {
                deb_gpio.timestamp_tran = tran_time;
                deb_gpio.gpio = target_state;
                state = NOT_DEBOUNCING;
                count = 0;

            } else if (count == 0) {
                count = 0;
                state = NOT_DEBOUNCING;
            }
            break;
        }
    }
    *gpio_out = deb_gpio.gpio;
    *trans_out = deb_gpio.timestamp_tran;
}

static inline void delay_cycles(volatile uint32_t count) {
    while (count--) {
        __asm__ volatile ("nop");
    }
}

static inline void ble_adv_packet(void) {
		//0x556b7d9171b14373cc31328d04ee0ce872f924dd6dd05b662a80
    static const uint8_t adv_data[26] = {
        0x55, 0x6b, 0x7d, 0x91, 0x71, 0xb1, 0x43, 0x73,
        0xcc, 0x31, 0x32, 0x8d, 0x04, 0xee, 0x0c, 0xe8,
        0x72, 0xf9, 0x24, 0xdd, 0x6d, 0xd0, 0x5b, 0x66,
        0x2a, 0x80
    };

    memcpy(ble_adv.packet, adv_data, sizeof(adv_data));
}

static inline void ble_scan_rsp_packet(void) {
    static const uint8_t scan_rsp_data[44] = {
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
				0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x55, 0x6b, 0x7d, 0x91, 0x71, 0x91, 0x7b, 0x73,
        0xcc, 0x31, 0x32, 0x8d, 0x04, 0x0e, 0x73, 0x88,
        0x52, 0x3c, 0xbb, 0xcc, 0x26, 0x13
    };

    memcpy(ble_rsp.packet, scan_rsp_data, sizeof(scan_rsp_data));
}

// mode = 1 tx (ble_tx.packet)
// mode = 0 rx (ble_rsp.packet)
static inline void ble_load_fifo_fast(bool mode) {
    uint8_t current_byte, current_bit;
    uint32_t fifo_ctrl_reg = 0x00000001;  // data in valid

    fifo_ctrl_reg &= 0xFFFFFFFB;  // data out not ready
    fifo_ctrl_reg &= 0xFFFFFFDF;  // clock in from Cortex

    ANALOG_CFG_REG__11 = fifo_ctrl_reg;

    // Select source buffer once
    const uint8_t* packet = mode ? ble_adv.packet : ble_rsp.packet;
    for (int i = 0; i < 64; ++i) {
        current_byte = packet[i];
        for (int j = 7; j >= 0; --j) {
            current_bit = (current_byte >> j) & 0x1;

            // Update bit 1 and write
            fifo_ctrl_reg = (fifo_ctrl_reg & ~0x2) | (current_bit << 1);
            ANALOG_CFG_REG__11 = fifo_ctrl_reg;

            // Toggle clock (bit 3)
            ANALOG_CFG_REG__11 = fifo_ctrl_reg | 0x8;
            ANALOG_CFG_REG__11 = fifo_ctrl_reg & ~0x8;
        }
    }
}

static inline void ble_tx_fifo(void) {
    // Set the desired bits directly in one go
    uint32_t fifo_ctrl_reg = ANALOG_CFG_REG__11 = 0x00000034;
    //    0x00000010 | // enable div-by-2
    //    0x00000004 | // data out ready
    //    0x00000020;  // choose clk = 1 (external or div-by-2)

    // Ensure data in valid bit (bit 0) is cleared
    fifo_ctrl_reg &= ~0x00000001;

    ANALOG_CFG_REG__11 = fifo_ctrl_reg;
}
void ble_connect_init(void){
	GPI_control(0,0,0,0);
	GPO_control(3,3,3,6);		// ADC CLK, I and Q_BPF, HCLK
	GPI_enables(0x8000);		// GPI pin #15 as packet_detected trigger
	GPO_enables(0x0FFF);
	analog_scan_chain_write();
	analog_scan_chain_load();
}
void ble_fake_connnect(){
	// load adv packet
	ble_adv_packet();	
	// load scan response packet();
	ble_scan_rsp_packet();
	
	LC_FREQCHANGE(20,2,8);
	radio_txEnable();
			// set fifo to adv packet
	ble_load_fifo_fast(1);
	// Send the packet.
	ble_tx_fifo();
	// @ target delay 476
	// set fifo to rsp packet
	ble_load_fifo_fast(0);
	// Send the packet.
	ble_tx_fifo();
	delay_cycles(1000); // @ target delay 284us
	
};

void ble_fast_connect(int cycles){
	unsigned short gpio_raw;
	unsigned short gpio_debounced;
	unsigned int gpio_transitions;
	unsigned int packet_count;
	int fine;

	// load adv packet
	ble_adv_packet();	
	// load scan response packet();
	ble_scan_rsp_packet();
	while (cycles > 0){	
		printf("cycles %d\r\n",cycles);
		// Send advertisment =================================
    radio_txEnable();
		LC_FREQCHANGE(20,2,5);
		// set fifo to adv packet
	  ble_load_fifo_fast(1);
    // Send the packet.
    ble_tx_fifo();
		// Scan request search ===============================
		// Rx frquency 2.3995 GHz (2.402GHz - 2.5MHz)
		
		LC_FREQCHANGE(20,1,15);
		radio_rxEnable();
		radio_rxNow();
		gpio_debounced = 0;
		gpio_transitions = 0;
		while (gpio_debounced == 0){
			// Trigger using GPI pin #15
			gpio_raw = ((0x8000 & GPIO_REG__INPUT)>> 14);
			debounce_gpio(gpio_raw, &gpio_debounced, &gpio_transitions);
		}
		// Send ADV + scan response ===============================
		LC_FREQCHANGE(20,2,5);
		radio_txEnable();
				// set fifo to adv packet
	  ble_load_fifo_fast(1);
    // Send the packet.
    ble_tx_fifo();
		__asm("nop");
		// set fifo to rsp packet
		ble_load_fifo_fast(0);
		// Send the packet.
    ble_tx_fifo();
		delay_cycles(1000); // @ target delay 284us
		cycles--;
	}
}
