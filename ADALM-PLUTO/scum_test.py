from Modules.link_layer import packet_gen, packet_decode
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.progressbar import printProgressBar
from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter

if __name__ == "__main__":
    freqs = {37: 2.405e09, 38: 2.426e09, 39: 2.480e09}
    symbol_time = 1e-6
    bt = 0.5
    tx_power = -50
    ifreq = 2.5e6
    freqs = {ch: f - ifreq for ch, f in freqs.items()}

    channels = [37]

    if input("Use AD2 or Pluto? (a/p) ").lower() == 'a':
        sdr = AD2Transmitter(freqs[37], symbol_time, bt, tx_power)
    else:
        sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq, sdr='ip:192.168.2.1')
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
                sdr.transmit(0)

    sdr.close()
