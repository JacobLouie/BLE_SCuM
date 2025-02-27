from Modules.link_layer import packet_gen
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.progressbar import printProgressBar
from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter


if __name__ == "__main__":
    interval = 0.2
    freqs = {37: 2.402e09, 38: 2.426e09, 39: 2.480e09}
    symbol_time = 1e-6
    bt = 0.5
    tx_power = -10
    ifreq = 2.5e6
    freqs = {ch: f - ifreq for ch, f in freqs.items()}
    channels = [37]
    # Connectable Packets
    packets = {ch: hex2bin(whiten_fullPacket(packet_gen('8e89bed6', 'ADV_IND', '90d7ebb19299', [['FLAGS', '06'], ['COMPLETE_LOCAL_NAME', 'SCUM3']]), ch)) for ch in channels}
    scanrspPackets = {ch: hex2bin(whiten_fullPacket(packet_gen('8e89bed6', 'SCAN_RSP', '90d7ebb19299', []), ch)) for ch in channels}

    if input("Use AD2 or Pluto? (a/p) ").lower() == 'a':
        sdr = AD2Transmitter(freqs[37], symbol_time, bt, tx_power)
    else:
        sdr = PlutoTransmitter(freqs[37], symbol_time, bt, tx_power, ifreq, sdr='ip:192.168.2.1')
        sdr.set_sample_rate()
    while True:
        try:
            # sdr.vsg.write_raw(b'OUTP OFF')
            amt = int(input("Enter the number of packet sets (ADV_IND and SCAN_RSP) to send: "))
            # sdr.vsg.write_raw(b'OUTP ON')
        except ValueError:
            print("Invalid input, exiting...")
            break

        for i in range(amt):
            printProgressBar(i + 1, amt, prefix="Progress:", suffix="Complete", length=50)
            for ch in channels:
                sdr.set_tx_freq(freqs[ch])
                sdr.set_packet(packets[ch])
                sdr.transmit(interval)
                sdr.set_packet(scanrspPackets[ch])
                sdr.transmit(interval)

    sdr.close()
    quit()
