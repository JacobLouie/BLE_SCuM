from Modules.link_layer import packet_gen
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.progressbar import printProgressBar
from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter


if __name__ == "__main__":
    freqs = {37: 2.402e09, 38: 2.426e09, 39: 2.480e09}
    symbol_time = 1e-6
    bt = 0.5
    tx_power = -50
    ifreq = 2.5e6
    freqs = {ch: f - ifreq for ch, f in freqs.items()}
    packet = hex2bin('0')

    if input("Use AD2 or Pluto? (a/p) ").lower() == 'a':
        sdr = AD2Transmitter(freqs[37], symbol_time, bt, tx_power)
    else:
        sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq, sdr='ip:192.168.2.1')
        sdr.set_sample_rate()

    print("Looping transmission of package in progress...")
    sdr.set_tx_freq(freqs[37])
    sdr.set_packet(packet)
    sdr.repeating_transmit()

    try:
        while True:
            pass
    except KeyboardInterrupt:
        print("\nStopping transmission...")
        sdr.close()
