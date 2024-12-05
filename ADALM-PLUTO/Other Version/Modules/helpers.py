import math
from collections import deque


def hex2bin(hex_val):
    bin_val = ''
    lut = {'0': '0000', '1': '0001', '2': '0010', '3': '0011', '4': '0100', '5': '0101', '6': '0110', '7': '0111', '8': '1000', '9': '1001', 'a': '1010', 'b': '1011', 'c': '1100', 'd': '1101', 'e': '1110', 'f': '1111', 'A': '1010', 'B': '1011', 'C': '1100', 'D': '1101', 'E': '1110', 'F': '1111'}
    for c in hex_val:
        bin_val += lut[c]

    return bin_val


def bin2hex(bin_val):
    # Only works for binary strings with length a multiple of 4 bits
    hex_val = ''
    lut = {'0000': '0', '0001': '1', '0010': '2', '0011': '3', '0100': '4', '0101': '5', '0110': '6', '0111': '7', '1000': '8', '1001': '9', '1010': 'a', '1011': 'b', '1100': 'c', '1101': 'd', '1110': 'e', '1111': 'f'}
    for i in range(0, len(bin_val), 4):
        substring = bin_val[i:i + 4]
        hex_val += lut[substring]

    return hex_val


def reverse_string(str):
    return str[::-1]


def string_bitwise_XOR(str1, str2):
    # Returns a string that is the result of the bitwise XOR between str1 and str2
    if len(str1) != len(str2):
        raise ValueError("Strings are of unequal length")
    
    val = bin(int(str1, 2) ^ int(str2, 2))[2:]
    return '0' * (len(str1) - len(val)) + val


def calcCRC(value, init = '555555', msb_first = True):
    if len(init) != 24:
        init = hex2bin(init)

    if not msb_first:
        init = reverse_string(init)

    if not isinstance(init, deque):
        crc = deque(init)
    else:
        crc = init

    if msb_first:
        poly = [-2, -4, -5, -7, -10, -11]
        for b in value:
            msb = crc.popleft()
            if b == msb:
                crc.append('0')
            else:
                crc.append('1')
                for pos in poly:
                    crc[pos] = '0' if crc[pos] == '1' else '1'
    else:
        poly = [10, 9, 6, 4, 3, 1]
        for b in value:
            msb = crc.pop()
            if b == msb:
                crc.appendleft('0')
            else:
                crc.appendleft('1')
                for pos in poly:
                    crc[pos] = '0' if crc[pos] == '1' else '1'
    
    return crc


def timeFunc(val, str1):
    return val


def calcCRC_bits(value, init = 0x555555):
    try:
        length = math.ceil(math.log2(value))
    except:
        length = 8

    if length % 8 != 0:
        length += 8 - (length % 8)

    poly = 0x65B
    mask = ~(1 << 24)
    crc = init

    for i in range(length):
        common = ((crc >> 23) & 1) ^ ((value >> (length - i - 1)) & 1)

        crc <<= 1
        crc &= mask

        if common:
            crc ^= poly

    return crc


def whiten_fullPacket(packet, channel):
    pre_accAddr = packet[:10]
    data = hex2bin(packet[10:])

    channel_bin = bin(channel)[2:]
    LFSR = [c for c in '1' + '0' * (6 - len(channel_bin)) + channel_bin]

    output = ''
    for b in data:
        output += str(int(b) ^ int(LFSR[-1]))
        LFSR = [LFSR[-1]] + LFSR[:-1]
        LFSR[4] = str(int(LFSR[4]) ^ int(LFSR[0]))

    return pre_accAddr + bin2hex(output)


def whiten(pduBits, channel):
    data = pduBits
    channel_bin = bin(channel)[2:]
    LFSR = [c for c in '1' + '0' * (6 - len(channel_bin)) + channel_bin]

    output = ''
    for b in data:
        output += str(int(b) ^ int(LFSR[-1]))
        LFSR = [LFSR[-1]] + LFSR[:-1]
        LFSR[4] = str(int(LFSR[4]) ^ int(LFSR[0]))

    return output


def whiten_bits(pduBits, channel):
    channel += 1 << 6

    length = math.ceil(math.log2(pduBits))
    if length % 8 != 0:
        length += 8 - (length % 8)

    for i in range(length):
        common = channel & 1
        channel >>= 1
        channel ^= (common << 6) + (common << 2)

        pduBits ^= (common << (length - i - 1))

    return pduBits


if __name__ == "__main__":
    pduBits = '0101010101101011011111011001000101110001111100010010001101110011110011000011000100110010100011010000010011101110000011000010100001110010111110010010010011011101011011011101000001011011011101011111010010000110100010101011000111101100010111110110100111110010'
    print(int(''.join(str(c) for c in calcCRC(whiten(pduBits[40:], 37), '555555', True))) == 0)
    from time import perf_counter
    import os
    from pathlib import Path
    with open(os.path.join(Path(__file__).parent.parent.parent, "Packet Strings/connectable.txt")) as f:
        packet_str = f.read()
        packet_int = int(packet_str, 2)

    loops = 100000

    whitenTime_str, crcTime_str = 0, 0
    for _ in range(loops):
        init_time = perf_counter()
        dewhitened = whiten(packet_str, 37)
        final_time = perf_counter()
        whitenTime_str += final_time - init_time

    for _ in range(loops):
        init_time = perf_counter()
        crc = calcCRC(dewhitened)
        final_time = perf_counter()
        crcTime_str += final_time - init_time

    whitenTime_int, crcTime_int = 0, 0
    for _ in range(loops):
        init_time = perf_counter()
        dewhitened = whiten_bits(packet_int, 37)
        final_time = perf_counter()
        whitenTime_int += final_time - init_time

    for _ in range(loops):
        init_time = perf_counter()
        crc = calcCRC_bits(dewhitened)
        final_time = perf_counter()
        crcTime_int += final_time - init_time

    whitenTime_str /= loops
    crcTime_str /= loops
    whitenTime_int /= loops
    crcTime_int /= loops

    print(f"For {loops} loops:")
    print(f"Strings: Whitening: {whitenTime_str} seconds, CRC: {crcTime_str} seconds")
    print(f"Integer: Whitening: {whitenTime_int} seconds, CRC: {crcTime_int} seconds")