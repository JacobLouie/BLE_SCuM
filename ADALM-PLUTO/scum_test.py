from Modules.link_layer import packet_gen, packet_decode
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.progressbar import printProgressBar
from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter

if __name__ == "__main__":
    freqs = {37: 2.405e09, 38: 2.426e09, 39: 2.480e09}
    MODE = 0    # 0 = 802.15.4
                # 1 = BLE
    if MODE == 0: # 802.15.4
        symbol_time = 0.5e-6 
        df = 500e3
        ifreq = 2.5e6
    else: # BLE
        symbol_time = 1e-6
        df = 250e3
        ifreq = 2.5e6

    bt = 0.5
    tx_power = -50
    freqs = {ch: f - ifreq for ch, f in freqs.items()}

    channels = [37]

    if input("Use AD2 or Pluto? (a/p) ").lower() == 'a':
        sdr = AD2Transmitter(freqs[37], symbol_time, bt, tx_power, df=df)
        sdr.set_sample_rate()
    else:
        sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq, df=df, sdr='ip:192.168.2.1')
        sdr.set_sample_rate()
        
    packet1 = hex2bin('556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6') # Packet for SCuM test
    #packet1 = hex2bin('556b7d9171b14373cc31328d04ee0ce872f924dd6dd05b662a80') # Adv Packet
    #packet1 = hex2bin('556b7d9171b14373cc31328d04ee0c0872f924dd6dd05bfc3e35') #Adv Packet 2
    
    #print(whiten_fullPacket(hex(int(packet1, 2)),37))

    #packet2 = hex2bin('556b7d9171917b73cc31328d040e7388523cbbcc2613') # Scan Response Packet

    #packet1 = hex2bin('F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F') #212 bits
    sdr.set_packet(packet1*100)
    sdr.set_tx_freq(freqs[37])

    while True:
        try:
            amt = int(input("How many packets to send: "))
        except ValueError:
            print("Invalid input, exiting...")
            break
        
        for i in range(amt):
            printProgressBar(i + 1, amt, prefix="Progress:", suffix="Complete", length=50)        
            for ch in channels:
                #sdr.set_packet(packet1*100)
                sdr.transmit(symbol_time*len(packet1*100)*2)
                

                #sdr.set_packet(packet2)
                #sdr.transmit(symbol_time*len(packet2*1)*2)
                

    sdr.close()
