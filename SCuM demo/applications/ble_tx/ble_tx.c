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
	  .coarse = 19,
    .mid = 15,
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

int main(void) {
    initialize_mote();

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
	  analog_scan_chain_write();
    analog_scan_chain_load();
    // Generate a BLE packet.
    //ble_generate_packet();
		//ble_gen_test_packet();
		//ble_adv_packet();
		//ble_scan_rsp_packet();
		
    while (true) {
				LC_FREQCHANGE(ble_ch_code.coarse,ble_ch_code.mid,ble_ch_code.fine);
				ble_adv_packet();
				ble_transmit();
			
				LC_FREQCHANGE(20,0,7); // 2.402GHz CF, 2.3995 Offset| 2.25MHz IF (BLE and 802)
				radio_rxEnable();
				radio_rxNow();
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
