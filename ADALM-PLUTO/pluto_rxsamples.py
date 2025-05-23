import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft, fftfreq
import csv
import threading
from argparse import ArgumentParser

from Modules.ble_hardware import PlutoTransmitter, PlutoReceiver
from Modules.helpers import hex2bin
from Modules.link_layer import packet_decode


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("-p", '--plot', action='store_true', help="Plot the received samples")
    parser.add_argument("-s", '--save', action='store_true', help="Save the received samples to a file")
    parser.add_argument("-d", '--decimate', action='store_true', help="Decimate the received samples")

    args = parser.parse_args()

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

    tx_sdr = PlutoTransmitter(center_freq, bit_time, 0.5, -70, IF)
    tx_sdr.set_packet(packet_bits)
    rx_sdr = PlutoReceiver(center_freq, bit_time, 0.5, sample_rate, IF)
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

    if args.save:
        if args.decimate:
            i >>= 8
            q >>= 8

        rows = zip(i, q)
        with open(f'Text Files/{input("Enter file name: ")}.csv', 'w', newline='', encoding="UTF-8") as f:
            writer = csv.writer(f)
            writer.writerow(['I', 'Q'])
            for row in rows:
                writer.writerow(row)

    if args.plot:
        fig, ax = plt.subplots()
        fig.set_figwidth(7)

        N = len(samples)
        T = bit_time / samples_per_bit
        yf = fft(samples)
        xf = fftfreq(N, T)[:N//2]

        ax.plot(xf, 2.0/N * np.abs(yf[0:N//2]))
        ax.grid()

        plt.show()