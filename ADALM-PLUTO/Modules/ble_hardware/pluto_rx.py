import adi


class PlutoReceiver:
    def __init__(self, channel_freq, cf, symbol_time=1e-6, bt=0.5, samples_per_bit=8, sdr=None):
        if sdr is None:
            self.sdr = adi.Pluto()
        elif isinstance(sdr, str):
            self.sdr = adi.Pluto(sdr)
        else:
            self.sdr = sdr

        self.rx_freq = int(channel_freq - cf)
        self.sdr.rx_lo = self.rx_freq
        self.sample_rate = samples_per_bit / symbol_time
        self.sdr.sample_rate = int(self.sample_rate)
        self.cf = cf
        self.df = bt / (symbol_time * 2)
        self.sdr.rx_rf_bandwidth = int(4 * max(abs(cf - self.df), abs(cf + self.df)))
        self.sdr.gain_control_mode_chan0 = 'manual'
        self.sdr.rx_hardwaregain_chan0 = 70.0
        self.symbol_time = symbol_time

    def set_rx_freq(self, rx_freq):
        self.rx_freq = int(rx_freq - self.cf)
        self.sdr.rx_lo = self.rx_freq

    def set_rx_gain(self, gain=70, mode='manual'):
        if mode not in ['manual', 'slow_attack', 'fast_attack', 'hybrid']:
            raise ValueError("Gain mode must be one of 'manual', 'slow_attack', 'fast_attack', or 'hybrid'")
        
        if mode == 'manual' and not 0 <= gain <= 70:
            raise ValueError("Gain must be in the range 0 to 70 dB")
        
        self.sdr.gain_control_mode_chan0 = mode
        if mode == 'manual':
            self.sdr.rx_hardwaregain_chan0 = gain

    def receive(self, num_samples=20000, clear_buffer=True):
        # self.sdr.rx_destroy_buffer()
        self.sdr.rx_buffer_size = num_samples
        if clear_buffer:
            self.sdr.rx_destroy_buffer()

        return self.sdr.rx()