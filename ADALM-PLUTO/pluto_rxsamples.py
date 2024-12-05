import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft, fftfreq
import csv
import threading

import sys
if sys.platform.startswith("win"):
    #sys.path.append("I:\Shared drives\west\Brandon Hippe\Research Projects\SCuM BLE\Code")
    #sys.path.append("I:\Shared drives\west\Brandon Hippe\Research Projects\SCuM BLE\Code\Modules")
    # Jacob path
    sys.path.append(r"C:\Users\6RF4001\Desktop\BLE_SCuM\ADALM-PLUTO\Modules")
    sys.path.append(r"C:\Users\6RF4001\Desktop\BLE_SCuM\ADALM-PLUTO\Modules\ble_hardware")
    sys.path.append(r"C:\Users\6RF4001\Desktop\BLE_SCuM\ADALM-PLUTO\Modules\link_layer")
    sys.path.append(r"C:\Users\6RF4001\Desktop\BLE_SCuM\ADALM-PLUTO\Modules\phy")
else:
    #sys.path.append("/home/brandonhippe/bhippe@pdx.edu Shared/Brandon Hippe/Research Projects/SCuM BLE/Code")
    #sys.path.append("/home/brandonhippe/bhippe@pdx.edu Shared/Brandon Hippe/Research Projects/SCuM BLE/Code/Modules")
    # Jacob path
    sys.path.append("/mnt/c/Users/6RF4001/Desktop/BLE_SCuM/ADALM-PLUTO/Modules") 
    sys.path.append("/mnt/c/Users/6RF4001/Desktop/BLE_SCuM/ADALM-PLUTO/Modules/ble_hardware") 
    sys.path.append("/mnt/c/Users/6RF4001/Desktop/BLE_SCuM/ADALM-PLUTO/Modules/link_layer") 
    sys.path.append("/mnt/c/Users/6RF4001/Desktop/BLE_SCuM/ADALM-PLUTO/Modules/phy") 

# old
#from Modules.pluto_tx import PlutoTransmitter
#from Modules.pluto_rx import PlutoReceiver
#from Python.Modules.helpers import hex2bin
#from ble_packet_decode import packet_decode

# Jacob path
from Modules.ble_hardware.pluto_tx import PlutoTransmitter
from Modules.ble_hardware.pluto_rx import PlutoReceiver
from Modules.helpers import hex2bin
from Modules.link_layer.ble_packet_decode import packet_decode


if __name__ == "__main__":
    center_freq = 2.402e9 # Hz
    IF = 2.5e6 # Hz
    num_samples = 250000
    sample_rate = 16e6 # Hz
    bit_time = 0.5e-6 # s
    samples_per_bit = sample_rate * bit_time
    packet_cycle_time = 0.5e-3 # s

    packet = '556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6'
    print(f"Packet: 0x{packet}")
    print(f"Raw PDU: 0x{packet_decode(packet, 37)}")
    packet_bits = hex2bin(packet)

    tx_sdr = PlutoTransmitter(center_freq, IF, bit_time, 0.5, -70, "ip:192.168.2.1")
    tx_sdr.set_packet(packet_bits)
    rx_sdr = PlutoReceiver(center_freq, IF, bit_time, 0.5, samples_per_bit)
    rx_sdr.set_rx_freq(center_freq)
    rx_sdr.set_rx_gain(70.0, 'manual')

    print("Starting transmitter!")
    tx_thread = threading.Thread(target=tx_sdr.transmit, args=(None, packet_cycle_time))
    tx_thread.start()

    samples = rx_sdr.receive(num_samples)

    tx_thread.alive = False
    tx_thread.join()

    print(len(samples), min(samples), max(samples), np.mean(samples))

    i = np.array(np.real(samples), dtype=int)
    q = np.array(np.imag(samples), dtype=int)

    if input("Save samples to file? (y/n) ").lower() == 'y':
        if input('Decimate samples? (y/n) ').lower() == 'y':
            i >>= 8
            q >>= 8

        rows = zip(i, q)
        with open(f'Text Files/{input("Enter file name: ")}.csv', 'w', newline='', encoding="UTF-8") as f:
            writer = csv.writer(f)
            writer.writerow(['I', 'Q'])
            for row in rows:
                writer.writerow(row)

    if 'plot' in sys.argv:
        fig, ax = plt.subplots()
        fig.set_figwidth(7)

        N = len(samples)
        T = bit_time / samples_per_bit
        yf = fft(samples)
        xf = fftfreq(N, T)[:N//2]

        ax.plot(xf, 2.0/N * np.abs(yf[0:N//2]))
        ax.grid()

        plt.show()