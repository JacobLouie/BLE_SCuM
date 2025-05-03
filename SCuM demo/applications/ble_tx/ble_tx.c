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
#include "ble_transceiver.h"

int main(void) {
    initialize_mote();

    // Initialize BLE TX.
    printf("Initializing BLE TX.\r\n");
    ble_init();
    ble_init_tx();	

    analog_scan_chain_write();
    analog_scan_chain_load();

    crc_check();
    perform_calibration();
		
		ble_connect_init();

    while (true) {
			//ble_fast_connect(100);
			ble_fake_connnect();
		}
}
