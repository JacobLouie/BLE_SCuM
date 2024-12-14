from Modules.link_layer import packet_gen, packet_decode
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.progressbar import printProgressBar
from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter

if __name__ == "__main__":
    freqs = {37: 2.404e09, 38: 2.426e09, 39: 2.480e09}
    symbol_time = 0.5e-6
    bt = 0.5
    tx_power = -40
    ifreq = 2.5e6 #1.25e6

    channels = [37, 38, 39]

    packet = hex2bin(whiten_fullPacket(packet_gen('8e89bed6', 'ADV_NONCONN_IND', '90d7ebb19299', [['FLAGS', '06'], ['COMPLETE_LOCAL_NAME', 'SCUM3']]), 37))
    rawPDU = packet_decode(packet, 37)

    print(f"Raw PDU: 0x{rawPDU}")
    
    #if input("Use AD2 or Pluto? (a/p) ").lower() == 'a':
    #    sdr = AD2Transmitter(freqs[37], symbol_time, bt, tx_power)
    #else:
    #    sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq)
    sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq)

    packet = hex2bin('AAAAAAAAAAAAAAA0F0F0F0F0FFF0F0F0F0F0F0AAAAAAAAAAAAAAA')
    sdr.set_packet(packet)

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
                sdr.transmit(1)

    sdr.close()
