import pyvisa
from ctypes import *
import sys
import os
from threading import current_thread

# load the dynamic library, get constants path (the path is OS specific)
if sys.platform.startswith("win"):
    # on Windows
    dwf = cdll.dwf
    constants_path = os.sep.join(["C:", "Program Files (x86)", "Digilent", "WaveFormsSDK", "samples", "py"])
elif sys.platform.startswith("darwin"):
    # on macOS
    lib_path = os.sep.join(["", "Library", "Frameworks", "dwf.framework", "dwf"])
    dwf = cdll.LoadLibrary(lib_path)
    constants_path = os.sep.join(["", "Applications", "WaveForms.app", "Contents", "Resources", "SDK", "samples", "py"])
else:
    # on Linux
    dwf = cdll.LoadLibrary("libdwf.so")
    constants_path = os.sep.join(["", "usr", "share", "digilent", "waveforms", "samples", "py"])

sys.path.append(constants_path)
from dwfconstants import *
from time import sleep


class AD2Transmitter:
    def __init__(self, tx_freq, symbol_time=1e-6, bt=0.5, tx_power=-50,):
        self.tx_freq = tx_freq
        self.packet = None
        if sys.platform.startswith("win"):
            dwf = cdll.dwf
        elif sys.platform.startswith("darwin"):
            dwf = cdll.LoadLibrary("/Library/Frameworks/dwf.framework/dwf")
        else:
            dwf = cdll.LoadLibrary("libdwf.so")

        hdwf = c_int()

        version = create_string_buffer(16)
        dwf.FDwfGetVersion(version)
        print("DWF Version: "+"".join(chr(c) for c in version.value))

        print("Opening first device")
        dwf.FDwfDeviceOpen(c_int(-1), byref(hdwf))

        if hdwf.value == 0:
            print("failed to open device")
            szerr = create_string_buffer(512)
            dwf.FDwfGetLastErrorMsg(szerr)
            print("".join(chr(c) for c in szerr.value))
            quit()

        self.ad2 = hdwf
        hzSys = c_double()
        dwf.FDwfDigitalOutInternalClockInfo(hdwf, byref(hzSys))
        self.hzSys = hzSys
        self.symbol_time = symbol_time
        self.df = bt / (symbol_time * 2)

        if sys.platform.startswith("win"):
            rm = pyvisa.ResourceManager()
            devs = rm.list_resources()

            if len(devs) == 0:
                raise ValueError("No devices found")

            for dev in devs:
                inst = rm.open_resource(dev)
                if 'E4438C' in inst.query('*IDN?'):
                    if input(f"Is {dev} the correct device? (y/n) ") == 'n':
                        inst.close()
                        continue

                    self.vsg = inst
                    break
            self.vsg.write_raw(b'RAD:CUST:DATA EXT')
            self.vsg.write_raw(b'RAD:CUST:FILT GAUS')
            self.vsg.write_raw(f'RAD:CUST:MOD:FSK:DEV {self.df}')
            self.vsg.write_raw(f'RAD:CUST:SRAT {1/symbol_time}')
            self.vsg.write_raw(f'POW {tx_power}')
            self.vsg.write_raw(f'FREQ:FIXED {self.tx_freq}')
        else:
            self.vsg = False
            print("VSG not supported on this platform, manual configuration required")
            print(f"FSK Deviation: {self.df}")
            print(f"Symbol Rate: {1/symbol_time}")
            print(f"Power: {tx_power}")
            print(f"Frequency: {self.tx_freq}")

            while input("Configuration complete? (y/n) ").lower() == 'n':
                continue
        

    def set_tx_freq(self, tx_freq):
        self.tx_freq = tx_freq
        if self.vsg:
            self.vsg.write_raw(f'FREQ:FIXED {self.tx_freq}')
        else:
            print(f"Frequency: {self.tx_freq}")
            while input("Frequency configured? (y/n) ").lower() == 'n':
                continue

    def set_packet(self, packet):
        self.packet = packet

    def set_tx_power(self, power):
        if not -136 <= power <= 20:
            raise ValueError("Power must be in the range -136 to 20 dB")
        
        if self.vsg:
            self.vsg.write_raw(f'POW {power}')
        else:
            print(f"Power: {power}")
            while input("Power configured? (y/n) ").lower() == 'n':
                continue

    def transmit(self, cycles=1, cycle_time=0.1):
        if self.packet is None:
            raise ValueError("No packet to transmit")
        
        if cycles is not None:
            for _ in range(cycles):
                self.single_transmit()
                sleep(cycle_time - (len(self.packet) * self.symbol_time))
        else:
            t = current_thread()
            t.alive = True
            while t.alive:
                self.single_transmit()
                sleep(cycle_time - (len(self.packet) * self.symbol_time))

    def single_transmit(self):
        # Generate Clock
        self.gen_clock()

        # Generate Data
        self.gen_data()

        # Set running time
        dwf.FDwfDigitalOutRunSet(self.ad2, c_double(len(self.packet) * self.symbol_time))

        # Start output
        dwf.FDwfDigitalOutConfigure(self.ad2, c_int(1))

        # Reset
        dwf.FDwfDigitalOutReset(self.ad2)

    def close(self):
        dwf.FDwfDeviceClose(self.ad2)
        if self.vsg:
            self.vsg.close()

    def gen_clock(self):
        # Prepare AD2 Clock Output
        # 1MHz pulse on IO pin 0
        dwf.FDwfDigitalOutEnableSet(self.ad2, c_int(0), c_int(1))
        # prescaler to 2MHz, SystemFrequency/1MHz/2
        dwf.FDwfDigitalOutDividerSet(self.ad2, c_int(0), c_int(int(self.hzSys.value/self.symbol_time/2)))
        # 1 tick high, 1 tick low
        dwf.FDwfDigitalOutCounterSet(self.ad2, c_int(1), c_int(0), c_int(1))

    def gen_data(self):
        # Prepare AD2 Data Output
        rgbdata=(c_ubyte*((len(self.packet)+7)>>3))(0)

        # array to bits in byte array
        for i in range(len(self.packet)):
            if self.packet[i] != '0':
                rgbdata[i>>3] |= 1<<(i&7)

        pin=1
        # generate pattern
        dwf.FDwfDigitalOutEnableSet(self.ad2, c_int(pin), c_int(1))
        dwf.FDwfDigitalOutTypeSet(self.ad2, c_int(pin), DwfDigitalOutTypeCustom)
        # 1MHz sample rate
        dwf.FDwfDigitalOutDividerSet(self.ad2, c_int(pin), c_int(int(self.hzSys.value/self.symbol_time))) # set sample rate
        dwf.FDwfDigitalOutDataSet(self.ad2, c_int(pin), byref(rgbdata), c_int(len(self.packet)))
