from Modules.link_layer import packet_gen, packet_decode
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.progressbar import printProgressBar
from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter

if __name__ == "__main__":
    freqs = {0:2.405e09, 37: 2.402e09, 38: 2.426e09, 39: 2.480e09} # 0 changed to 2.405 for SCuM test only
    #symbol_time = 0.5e-6 #802.15.4
    symbol_time = 1e-6 #BLE
    bt = 0.5
    tx_power = -50
    ifreq = 2.5e6

    # channels = [0, 37, 38, 39]
    channels = [0]
    #packet = hex2bin(whiten_fullPacket(packet_gen('8e89bed6', 'ADV_NONCONN_IND', '90d7ebb19299', [['FLAGS', '06'], ['COMPLETE_LOCAL_NAME', 'SCUM3']]), 37))
    #rawPDU = packet_decode(packet, 37)

    #print(f"Raw PDU: 0x{rawPDU}")
   
    
    if input("Use AD2 or Pluto? (a/p) ").lower() == 'a':
        sdr = AD2Transmitter(freqs[0], symbol_time, bt, tx_power)
    else:
        sdr = PlutoTransmitter(freqs[0], symbol_time, bt, tx_power, ifreq)
        sdr.set_sample_rate()

    packet = hex2bin('1556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6') # Packet for SCuM test
    #packet = hex2bin('F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F') #212 bits
    sdr.set_packet(packet*100)

    while True:
        try:
            amt = int(input("How many packets to send: "))
        except ValueError:
            print("Invalid input, exiting...")
            break
        
        for i in range(amt):
            printProgressBar(i + 1, amt, prefix="Progress:", suffix="Complete", length=50)
            for ch in channels:
                sdr.set_tx_freq(freqs[ch])
                sdr.transmit(1,0)

    sdr.close()
