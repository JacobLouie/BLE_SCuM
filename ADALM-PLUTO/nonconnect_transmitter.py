from Modules.link_layer import packet_gen, packet_decode
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.progressbar import printProgressBar
from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter

if __name__ == "__main__":
    freqs = {37: 2.402e09, 38: 2.426e09, 39: 2.480e09}
    symbol_time = 1.0e-6
    bt = 0.5
    tx_power = -50
    ifreq = 2.5e6 #1.25e6

    channels = [37, 38, 39]

    packet = hex2bin(whiten_fullPacket(packet_gen('8e89bed6', 'ADV_NONCONN_IND', '90d7ebb19299', [['FLAGS', '06'], ['COMPLETE_LOCAL_NAME', 'SCUM3']]), 37))
    rawPDU = packet_decode(packet, 37)

    #print(f"Raw PDU: 0x{rawPDU}")
    
    #if input("Use AD2 or Pluto? (a/p) ").lower() == 'a':
    #    sdr = AD2Transmitter(freqs[37], symbol_time, bt, tx_power)
    #else:
    #    sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq)
    sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq)

    #packet = hex2bin('AAAAAAAAAAAAAAA0F0F0F0F0FFF0F0F0F0F0F0AAAAAAAAAAAAAAA')
    #packet = hex2bin('FFFFFFF0F0F0F0F0F0F0F0F0F0F0F0FFF0F0F0F0F0F0FFFFFFFFF')
    packet = hex2bin('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA')
    #packet = hex2bin('F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F')
    #packet = hex2bin('f0f01556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6')
    sdr.set_packet(packet*100)

    while True:
        try:
            amt = int(input("How many packets to send: "))
        except ValueError:
            print("Invalid input, exiting...")
            break
        
        for i in range(amt):
            #printProgressBar(i + 1, amt, prefix="Progress:", suffix="Complete", length=50)
            for ch in channels:
                sdr.set_tx_freq(freqs[ch])
                sdr.transmit(1,0)

    sdr.close()
