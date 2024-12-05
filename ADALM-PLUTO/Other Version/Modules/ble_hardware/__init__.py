__all__ = ["Transmitter", "Receiver", "AD2Transmitter", "PlutoTransmitter", "PlutoReceiver"]

class Transmitter:
    def __init__(self, tx_freq: float, symbol_time: float, bt: float, tx_power: float, *args, **kwargs):
        self.set_tx_freq(tx_freq)
        self.set_tx_power(tx_power)
        self.symbol_time = symbol_time
        self.bt = bt
        self.df = bt / (symbol_time * 2)

    def set_tx_power(self, tx_power: float):
        raise NotImplementedError("set_tx_power must be implemented by subclass")

    def set_tx_freq(self, tx_freq: float):
        raise NotImplementedError("set_tx_freq must be implemented by subclass")

    def set_packet(self, packet: str):
        raise NotImplementedError("set_packet must be implemented by subclass")

    def transmit(self, packet_cycle_time: float):
        raise NotImplementedError("transmit must be implemented by subclass")

    def close(self):
        raise NotImplementedError("close must be implemented by subclass")

class Receiver:
    def __init__(self, rx_freq: float, symbol_time: float, bt: float, samples_per_bit: float, *args, **kwargs):
        self.set_rx_freq(rx_freq)
        self.symbol_time = symbol_time
        self.bt = bt
        self.df = bt / (symbol_time * 2)
        self.samples_per_bit = samples_per_bit

    def set_rx_freq(self, rx_freq: float):
        raise NotImplementedError("set_rx_freq must be implemented by subclass")

    def receive(self, num_samples: int):
        raise NotImplementedError("receive must be implemented by subclass")

    def close(self):
        raise NotImplementedError("close must be implemented by subclass")

from .ad2_vsg_tx import AD2Transmitter
from .pluto_tx import PlutoTransmitter
from .pluto_rx import PlutoReceiver
