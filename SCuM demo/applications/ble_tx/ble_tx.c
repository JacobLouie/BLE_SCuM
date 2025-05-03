#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "ble.h"
#include "memory_map.h"
#include "optical.h"
#include "radio.h"
#include "rftimer.h"
#include "scm3c_hw_interface.h"
#include "tuning.h"

// If true, sweep through all fine codes.
#define BLE_TX_SWEEP_FINE false

// BLE TX period in milliseconds.
#define BLE_TX_PERIOD_MS 100  // milliseconds

// BLE TX tuning code.

static channel_code_t ble_ch_code = {
	// Channel 37
	// 2.402 GHz
	  .coarse = 20,
    .mid = 0,
    .fine = 15,	
};

// BLE TX trigger.
static bool g_ble_tx_trigger = true;

// Transmit BLE packets.
static inline void ble_tx_trigger(void) {
		//LC_FREQCHANGE(ble_ch_code.coarse1,ble_ch_code.mid1,ble_ch_code.fine1);
    // Wait for frequency to settle.
    //for (uint32_t t = 0; t < 5000; ++t);
    ble_transmit();
}


static void ble_tx_rftimer_callback(void) {
    // Trigger a BLE TX.
    g_ble_tx_trigger = true;
}

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

int main(void) {
    initialize_mote();
		unsigned short gpio_raw;
		unsigned short gpio_debounced;
		unsigned int gpio_transitions;
		unsigned int packet_count;
    // Initialize BLE TX.
    printf("Initializing BLE TX.\r\n");
    ble_init();
    ble_init_tx();

    // Configure the RF timer.
    rftimer_set_callback_by_id(ble_tx_rftimer_callback, 7);
    rftimer_enable_interrupts();
    rftimer_enable_interrupts_by_id(7);
	

    analog_scan_chain_write();
    analog_scan_chain_load();

    crc_check();
    perform_calibration();
		
		GPI_control(0,0,0,0);
		GPO_control(3,3,3,6);		// ADC CLK, I and Q_BPF, HCLK
		GPI_enables(0x8000);
		GPO_enables(0x0FFF);
	  analog_scan_chain_write();
    analog_scan_chain_load();
    // Generate a BLE packet.
		//ble_adv_packet();
		//ble_scan_rsp_packet();
		packet_count = 0;
    while (true) {
				/*
				LC_FREQCHANGE(ble_ch_code.coarse,ble_ch_code.mid,ble_ch_code.fine);
				ble_adv_packet();
				ble_transmit();
			
				LC_FREQCHANGE(20,0,7); // 2.402GHz CF, 2.3995 Offset| 2.25MHz IF (BLE and 802)
				radio_rxEnable();
				radio_rxNow();
				for (uint32_t t = 0; t < 10000; ++t);
				*/
				LC_FREQCHANGE(20,3,4);
				radio_rxEnable();
				radio_rxNow();
				gpio_debounced = 0;
				gpio_transitions = 0;
				while (gpio_debounced == 0){
					// Trigger using GPI pin #15
					gpio_raw = ((0x8000 & GPIO_REG__INPUT)>> 14);
					debounce_gpio(gpio_raw, &gpio_debounced, &gpio_transitions);
					//printf("GPIO_debounced: %d, GPIO_transitions %d\r\n",gpio_debounced,gpio_transitions);
				}
				packet_count++;
				printf("Packet Detected %d\r\n",packet_count);
				for (uint32_t t = 0; t < 10000; ++t);
			
				//ble_scan_rsp_packet();
				//ble_transmit();
				/*
        if (g_ble_tx_trigger) {
						ble_adv_packet();
            ble_transmit();
						ble_scan_rsp_packet();
            ble_transmit();
						g_ble_tx_trigger = false;
            delay_milliseconds_asynchronous(BLE_TX_PERIOD_MS, 7);	
        }
				*/	
				/*
				if (g_ble_tx_trigger) {
						ble_scan_rsp_packet();
            ble_tx_trigger();
            g_ble_tx_trigger = false;
            delay_milliseconds_asynchronous(BLE_TX_PERIOD_MS, 7);
        }
				*/
    }
}
