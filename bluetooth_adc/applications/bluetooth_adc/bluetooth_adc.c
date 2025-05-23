#include "stdio.h"
#include "optical.h"
#include "scm3c_hw_interface.h"
#include "radio.h"
#include "rftimer.h"

#include "memory_map.h"

void LCsweepMid(int MIDstart, int MIDend);
void LCsweepFine(int MID, int FINEstart, int FINEend);


int main(void){
	int mid, fine, i;

	
	initialize_mote();
	crc_check();
	perform_calibration();
	
	GPI_control(0,0,0,0);
	GPO_control(3,3,3,6);		// ADC CLK, I and Q_BPF, HCLK
	
	ANALOG_CFG_REG__10 = 0x0018; // turn off divider

	
	//LC_FREQCHANGE(20,15,18);	// 2.405GHz CF, 2.4025 Offset| 2.5MHz IF (BLE and 802)
	//LC_FREQCHANGE(20,15,20);	// 2.405GHz CF, 2.4025 Offset| 2.5MHz IF (BLE and 802)

	
	//LC_FREQCHANGE(20,15,22);	// 2.405GHz CF, 2.4025 Offset| 2.25MHz IF (BLE and 802)
	//LC_FREQCHANGE(20,15,10); // 2.405GHz CF, 2.4025 Offset| 2.25MHz IF (BLE and 802)
	LC_FREQCHANGE(20,3,23); // 2.405GHz CF, 2.4025 Offset| 2.25MHz IF (BLE and 802)
	
	//LC_FREQCHANGE(20,0,5); // 2.402GHz CF, 2.3995 Offset| 2.25MHz IF (BLE and 802)
	//LC_FREQCHANGE(19,15,22); // 2.402GHz CF, 2.3995 Offset| 2.25MHz IF (BLE and 802)
	
	// Program analog scan chain
  analog_scan_chain_write();
  analog_scan_chain_load();
	
	radio_rxEnable();
	radio_rxNow();
	
	//LCsweepMid(6,15);
	//LCsweepFine(3,0,30);

	
	
	printf("done\r\n");
	
	while(1);

}
void LCsweepMid(int MIDstart, int MIDend){
	int mid = MIDstart;
	int fine = 0;
	int i;
	
	while(mid < 31){
		while(fine < 31){
			LC_FREQCHANGE(20,mid,fine);
			fine++;
			for(i=0; i<100; i++); //wait
		}
		mid++;
		if (mid == MIDend) mid = MIDstart; fine = 0;
	}
};


void LCsweepFine(int MID, int FINEstart, int FINEend){
	int fine = FINEstart;
	int i;
		
	while(fine < 31){
		LC_FREQCHANGE(20,MID,fine);
		fine++;
		for(i=0; i<10000; i++);
		if (fine == FINEend) fine = FINEstart;
	}
};
