#include "stdio.h"
#include "optical.h"
#include "scm3c_hw_interface.h"
#include "radio.h"
#include "rftimer.h"

#include "memory_map.h"

//=========================== defines =========================================

#define RX_PACKET_LEN 8+2  // 2 for CRC 

//=========================== variables =======================================

typedef struct {
    uint8_t dummy;
} app_vars_t;

app_vars_t app_vars;

//=========================== prototypes ======================================
void radio_rx_cb(uint8_t* packet, uint8_t packet_len);

int main(void){
	int mid, fine, i;
	repeat_rx_tx_params_t repeat_params;
  memset(&app_vars, 0, sizeof(app_vars_t));
	
	initialize_mote();
	crc_check();
	perform_calibration(); 												// in this function, needed to change LO target to 2.3995GHz

	//ANALOG_CFG_REG__3 = 0x60;
	
	GPI_control(0,0,0,0);
	GPO_control(3,3,3,6);		// ADC CLK, I and Q_BPF, HCLK
	//GPO_control(3,6,1,1);	// ADC CLK, I and Q_LC
	
	ANALOG_CFG_REG__10 = 0x0018; // turn off divider



	//LC_FREQCHANGE(20,12,9); // 2.402GHz CF
	//LC_FREQCHANGE(20,16,9);	// 2.405GHz CF
	//LC_FREQCHANGE(20,16,12);	// 2.405GHz CF
	//LC_FREQCHANGE(20,16,8);	// 2.405GHz CF
	
	// Program analog scan chain
  analog_scan_chain_write();
  analog_scan_chain_load();

	radio_rxEnable();
	radio_rxNow();
	

	/*
	mid = 18;
	fine = 0;
	
	while(mid < 31){
		while(fine < 31){
			LC_FREQCHANGE(20,mid,fine);
			fine++;
			for(i=0; i<100; i++);
		}
		mid++;
		if (mid == 23) mid = 18; fine = 0; //21-23 for TX 802.15.4
		//18-12
	}
	*/
	/*
	fine = 0;
	while(fine < 31){
			LC_FREQCHANGE(20,12,fine); //18 //20 //13
			fine++;
			for(i=0; i<100; i++);
			if (fine == 31) fine = 0;
	}
	*/
	
	
	radio_setRxCb(radio_rx_cb);
	

	repeat_params.packet_count = -1;
	repeat_params.pkt_len = RX_PACKET_LEN;
	repeat_params.radio_mode = RX_MODE;
	repeat_params.repeat_mode = FIXED;	//SWEEP
	repeat_params.sweep_lc_coarse_start = 20; 
	repeat_params.sweep_lc_coarse_end = 21;	
	repeat_params.sweep_lc_mid_start = 16;	
	repeat_params.sweep_lc_mid_end = 17;
	repeat_params.sweep_lc_fine_start = 0;
	repeat_params.sweep_lc_fine_end = 31;
	repeat_params.fixed_lc_coarse = 20;
	repeat_params.fixed_lc_mid = 16;	
	repeat_params.fixed_lc_fine = 16;//8	

	//repeat_rx_tx(repeat_params);
	
	printf("done\r\n");
	
	while(1);

}


//=========================== private =========================================
void radio_rx_cb(uint8_t* packet, uint8_t packet_len) {
    uint8_t i;

    // Log the packet
    printf("rx_simple: Received Packet. Contents: ");

    for (i = 0; i < packet_len - LENGTH_CRC; i++) {
        printf("%c", packet[i]);
    }
    printf("\r\n");
}