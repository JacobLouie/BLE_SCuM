import os
from pathlib import Path
from collections import deque
import numpy as np
from math import ceil
import csv
import time
import threading
import multiprocessing as mp
from argparse import ArgumentParser

from Modules.ble_hardware import AD2Transmitter, PlutoTransmitter, PlutoReceiver
from Modules.helpers import hex2bin, whiten_fullPacket
from Modules.link_layer import packet_gen
from Modules.phy.demodulation import *

recordings_path = os.path.join(Path(__file__).parent.parent, "Receiver Recordings")


def iterate_matches(matches, limit):
    yield
    i = 0
    while i < len(matches):
        amt, ix = matches[i]
        limit = yield (ix, amt), ix > limit
        i += 1

    yield None, True


def calc_ber(cf, df, ts, samples_per_bit, adc_samples, template_amp, packet, num_packets, tx_power, save):
    adc_data = np.array([complex(int(np.real(sample)) >> 8, int(np.imag(sample)) >> 8) for sample in adc_samples])
    if save:
        rows = zip(np.real(adc_data), np.imag(adc_data))
        with open(os.path.join(recordings_path, f'rx_sen_ber_{f"{tx_power:.3f}".replace(".", "_")}db.csv'), 'w', newline='', encoding="UTF-8") as f:
            writer = csv.writer(f)
            writer.writerow(['I', 'Q'])
            for row in rows:
                writer.writerow(row)

    matches = cdr(cf, df, ts, samples_per_bit, adc_data, template_amp, search_for=np.fromiter(packet[8:], dtype=int), e_k_shift=5, tau_shift=8, high_pos=2)[0]

    total_expected = 0
    total_recovered = 0
    window = deque()
    match_ixs = []
    match_vals = []
    upper = len(packet)

    match_iterator = iterate_matches(matches, upper)
    match_iterator.send(None)
    while True:
        match, is_over = match_iterator.send(upper)
        if is_over:
            if len(window) > 0:
                max_ix = 0
                for i in range(1, len(window)):
                    if window[i][1] > window[max_ix][1]:
                        max_ix = i

                max_match = window[max_ix]
                match_ixs.append(max_match[0])
                match_vals.append(max_match[1])

                total_expected += len(packet)
                total_recovered += max_match[1]
                upper = max_match[0] + len(packet) + 1

            while len(window) > 0 and window[0][0] <= upper - len(packet):
                window.popleft()

        if match is None:
            break

        window.append(match)

    return (total_expected - total_recovered) / total_expected


def calc_per(cf, df, ts, samples_per_bit, adc_samples, template_amp, packet, num_packets, tx_power, save):
    adc_data = np.array([complex(int(np.real(sample)) >> 8, int(np.imag(sample)) >> 8) for sample in adc_samples])
    if save:
        rows = zip(np.real(adc_data), np.imag(adc_data))
        with open(os.path.join(recordings_path, f'rx_sen_per_{f"{tx_power:.3f}".replace(".", "_")}db.csv'), 'w', newline='', encoding="UTF-8") as f:
            writer = csv.writer(f)
            writer.writerow(['I', 'Q'])
            for row in rows:
                writer.writerow(row)
            
    matches = cdr(cf, df, ts, samples_per_bit, adc_data, template_amp, search_for=np.fromiter(packet[8:], dtype=int), e_k_shift=5, tau_shift=8, high_pos=2)[0]

    window = deque()
    match_ixs = []
    match_vals = []
    upper = len(packet)

    match_iterator = iterate_matches(matches, upper)
    match_iterator.send(None)
    while True:
        match, is_over = match_iterator.send(upper)
        if is_over:
            if len(window) > 0:
                max_ix = 0
                for i in range(1, len(window)):
                    if window[i][1] > window[max_ix][1]:
                        max_ix = i

                max_match = window[max_ix]
                match_ixs.append(max_match[0])
                match_vals.append(max_match[1])

                upper = max_match[0] + len(packet) + 1

            while len(window) > 0 and window[0][0] <= upper - len(packet):
                window.popleft()

        if match is None:
            break

        window.append(match)

    packet_amt = ceil(2 * num_packets / 3)
    num_found = min(len(match_vals), packet_amt)
    start_ix = (len(match_vals) - num_found) // 2
    end_ix = start_ix + num_found + 1
    middle_vals = match_vals[start_ix:end_ix]
    valid_count = 0
    for val in middle_vals:
        if val == len(packet) - 8:
            valid_count += 1
    
    return 1 - (valid_count / max(packet_amt, len(middle_vals)))


def test_sensitivity(transmitter, receiver, calc_func, acceptable_error, upper_limit, lower_limit, packet_cycle_time, num_symbols, samples_per_bit, template_amp, packet, num_packets, save):
    while upper_limit - lower_limit > 0.1:
        start_time = time.perf_counter()
        print(f"Receiver Sensitivity upper limit: {upper_limit} dBm\tLower limit: {lower_limit} dBm")
        transmit_powers = np.linspace(upper_limit, lower_limit, os.cpu_count() - 1)
        tx_thread = threading.Thread(target=transmitter.transmit, args=(None, packet_cycle_time))
        tx_thread.start()

        tx_power_data = {}
        for tx_power in transmit_powers:
            transmitter.set_tx_power(tx_power)
            tx_power_data[tx_power] = receiver.receive(num_samples=num_symbols * samples_per_bit)

        tx_thread.alive = False
        tx_thread.join()

        p = mp.Pool()
        error_rates = p.starmap(calc_func, [(cf, receiver.df, ts, samples_per_bit, tx_power_data[tx_power], template_amp, packet, num_packets, tx_power) for tx_power in transmit_powers])

        for tx_power, err in zip(transmit_powers, error_rates):
            print(f"TX Power: {tx_power} dBm\tError_rate: {err * 100:.2f}%")

        for i in range(len(transmit_powers)):
            if error_rates[i] < acceptable_error:
                upper_limit = transmit_powers[i]

            if error_rates[-i - 1] > acceptable_error:
                lower_limit = transmit_powers[-i - 1]

        print(f"Iteration Time: {time.perf_counter() - start_time:.2f}s")

    return upper_limit


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--pluto", action='store_true', help="Use ADALM-PLUTO")
    parser.add_argument("--ad2", action='store_true', help="Use AD2")
    parser.add_argument("--ber", action='store_true', help="Calculate Receive Sensitivity using BER")
    parser.add_argument("--per", action='store_true', help="Calculate Receive Sensitivity using PER")
    parser.add_argument("--save", action='store_true', help="Save the received samples to a file")

    args = parser.parse_args()

    channel_freqs = {37: 2.402e9, 38: 2.426e9, 39: 2.480e9}
    channel = 37
    cf = 2.5e6
    ts = 0.5e-6
    bt = 0.5
    samples_per_bit = 8
    template_amp = 15

    if args.pluto:
        print("Using ADALM-PLUTO")
        transmitter = PlutoTransmitter(channel_freqs[channel], ts, bt, -70, cf)
        upper_limit, lower_limit = -40, -89
    elif args.ad2:
        print("Using AD2")
        transmitter = AD2Transmitter(channel_freqs[channel], ts, bt, -70)
        upper_limit, lower_limit = -40, -89
    else:
        raise ValueError("No hardware specified")

    if args.ber:
        print("Calculating Receive Sensitivity using BER")
        calc_func = calc_ber
        acceptable_error = 0.001
    elif args.per:
        print("Calculating Receive Sensitivity using PER")
        calc_func = calc_per
        acceptable_error = 0.308
    else:
        raise ValueError("No calculation method specified")
    
    receiver = PlutoReceiver(channel_freqs[channel], ts, bt, samples_per_bit / ts, cf)
    receiver.set_rx_gain(mode='fast_attack', gain=70)
    packet = hex2bin(whiten_fullPacket(packet_gen('8e89bed6', 'ADV_NONCONN_IND', '90d7ebb19299', [['FLAGS', '06'], ['COMPLETE_LOCAL_NAME', 'SCUM3']]), channel))
    transmitter.set_packet(packet)

    num_packets = 100
    packet_cycle_time = 0.5e-3
    num_symbols = ceil(num_packets * (packet_cycle_time / ts))
    print(f"Number of symbols: {num_symbols}")

    print(f"\nReceiver sensitivity: {test_sensitivity(transmitter, receiver, calc_func, acceptable_error, upper_limit, lower_limit, packet_cycle_time, num_symbols, samples_per_bit, template_amp, packet, num_packets, args.save)} dB")
    transmitter.close()
