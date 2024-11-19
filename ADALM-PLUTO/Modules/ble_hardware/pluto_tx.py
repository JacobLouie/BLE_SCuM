from time import sleep
from iq import createFSK
import adi
from threading import current_thread


class PlutoTransmitter:
    def __init__(self, channel_freq, cf, symbol_time=1e-6, bt=0.5, tx_power=-50, sdr=None):
        if sdr is None:
            self.sdr = adi.Pluto()
        elif isinstance(sdr, str):
            self.sdr = adi.Pluto(sdr)
        else:
            self.sdr = sdr
        
        self.tx_freq = int(channel_freq - cf)
        self.sdr.tx_lo = self.tx_freq
        self.sample_rate = 16e6
        self.sdr.sample_rate = int(self.sample_rate)
        self.sdr.tx_hardwaregain_chan0 = tx_power
        self.packet = None
        self.samples = None
        self.symbol_time = symbol_time
        self.cf = cf
        self.df = bt / (symbol_time * 2)
        self.sdr.tx_rf_bandwidth = int(4 * max(abs(cf - self.df), abs(cf + self.df)))

    def set_tx_freq(self, tx_freq):
        self.tx_freq = int(tx_freq)
        self.sdr.tx_lo = self.tx_freq

    def set_packet(self, packet):
        self.sdr.tx_destroy_buffer()
        self.packet = packet
        self.samples = createFSK(self.packet, 2 ** 14, self.cf, self.df, samples_per_bit=self.sample_rate * self.symbol_time, bit_time=self.symbol_time)

    def set_tx_power(self, power):
        if not -90 <= power <= 0:
            raise ValueError("Power must be in the range -90 to 0 dB")
        
        self.sdr.tx_hardwaregain_chan0 = power

    def transmit(self, cycles=None, cycle_time=1e-3):
        if self.samples is None:
            raise ValueError("No samples to transmit")
        
        sleep_time = cycle_time - (self.symbol_time * len(self.samples) / self.sample_rate)

        if cycles is None:
            t = current_thread()
            t.alive = True

            while t.alive:
                self.sdr.tx(self.samples)
                sleep(sleep_time)
        else:
            for _ in range(cycles):
                self.sdr.tx(self.samples)
                sleep(sleep_time)

    def close(self):
        self.sdr.tx_destroy_buffer()
        # self.sdr.close()