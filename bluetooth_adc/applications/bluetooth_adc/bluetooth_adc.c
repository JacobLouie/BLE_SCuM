#include "stdio.h"
#include "optical.h"
#include "scm3c_hw_interface.h"
#include "radio.h"
#include "rftimer.h"

#include "memory_map.h"

//void radioControl();


int main(void){
	int mid, fine, i;
	
	initialize_mote();
	crc_check();
	perform_calibration(); 												// in this function, needed to change LO target to 2.3995GHz
	
	ANALOG_CFG_REG__3 = 0x60;
	

	//----------------------------------------------------------------------------------------//
	//LC_FREQCHANGE(24,15,1); //Both I and Q on //2MHz-3MHz //500 freq dev, 2Msps (I/Q_BPF)(nRF 5V, PS 1.8V) (802.15.4) L18 
	//LC_FREQCHANGE(25,12,15); //Both I and Q on //2MHz-3MHz //500 freq dev, 2Msps (I/Q_BPF)(nRF 5V, PS 1.8V) (802.15.4) M9 
	//LC_FREQCHANGE(24,11,6); //Both I and Q on //2MHz-3MHz //500 freq dev, 2Msps (I/Q_BPF)(nRF 5V, PS 1.8V) (802.15.4) L18
	//LC_FREQCHANGE(24,12,19); //Both I and Q on //2MHz-3MHz //500 freq dev, 2Msps (I/Q_BPF)(nRF 5V) (802.15.4) L18
	//LC_FREQCHANGE(24,12,7); //Both I and Q on //2MHz-3MHz //500 freq dev, 2Msps (I/Q_BPF)(nRF 5V, PS 1.8V) (802.15.4) L18 
	//LC_FREQCHANGE(24,12,9); //Both I and Q on //2MHz-3MHz //500 freq dev, 2Msps (I/Q_BPF)(nRF 5V, PS 1.8V) (802.15.4) L18 
	//LC_FREQCHANGE(24,12,11); //Both I and Q on //2MHz-3MHz //500 freq dev, 2Msps (I/Q_BPF)(nRF 5V, PS 1.8V) (802.15.4) L18 
	//GPO_control(1,6,5,5); 	// MF_OUTPUT
	//GPO_control(1,6,1,1);		// I_LC
	//rftimer_set_callback_by_id(radioControl, 1);
	//rftimer_set_callback_by_id(radio_rfOff, 2);
	//radioControl();
	
	GPI_control(0,0,0,0);
	GPO_control(3,3,3,6);		// ADC CLK, I and Q_BPF, HCLK
	//GPO_control(3,6,1,1);	// ADC CLK, I and Q_LC
	
	ANALOG_CFG_REG__10 = 0x0018; // turn off divider
	//LC_FREQCHANGE(24,4,6);		//-500kHz from true 2.04GHz CF

	//LC_FREQCHANGE(20,12,12);		
	LC_FREQCHANGE(20,12,3);	//-500kHz from true 2.04GHz CF


	// Program analog scan chain
  analog_scan_chain_write();
  analog_scan_chain_load();

	radio_rxEnable();
	radio_rxNow();
	

	/*
	while(1){
		delay_milliseconds_synchronous(1000, 1);	// rx on timer
		delay_milliseconds_synchronous(1000, 2);	// rx off timer
		//printf("Radio OFF\r\n");

	}
	*/
	//radio_txEnable();
	//radio_txNow();
	
	//SWEEP CODE
	
	/*
	mid = 15;
	fine = 0;
	
	while(mid < 31){
		while(fine < 31){
			LC_FREQCHANGE(20,mid,fine);
			fine++;
			for(i=0; i<100; i++);
		}
		mid++;
		if (mid == 16) mid = 15; fine = 0; //21-23 for TX 802.15.4
		//18-12
	}
	*/
	/*
	fine = 15;
	while(fine < 31){
			LC_FREQCHANGE(20,15,fine); //18 //20 //13
			fine++;
			for(i=0; i<100; i++);
			if (fine == 31) fine = 15;
	}
	*/
	printf("done\r\n");
	
	while(1);

}
//void radioControl(){
//		radio_rxEnable();
//		radio_rxNow();
		//printf("radio ON\r\n");
//}