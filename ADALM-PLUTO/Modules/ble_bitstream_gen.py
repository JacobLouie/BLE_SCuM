import random
from os import path, pardir


def bitstream_gen(numPackets, totalBits):
    random.seed()

    with open(path.join(path.dirname(__file__), pardir, "Text Files/testpacket.txt")) as f:
        packet_bits = hex2bin(f.readline())

    bits = totalBits - (numPackets * len(packet_bits))
    bitstream = bin(random.getrandbits(bits))[2:]
    bitstream = '0' * (bits - len(bitstream)) + bitstream

    startIndexes = sorted(random.choices(range(numPackets), k = numPackets))
    indexes = []
    
    for i, base_ix in enumerate(startIndexes):
        index = i * len(packet_bits) + base_ix
        bitstream = bitstream[:index] + packet_bits + bitstream[index:]
        indexes.append(index)

    return bitstream, indexes


if __name__ == "__main__":
    from Python.Modules.helpers import hex2bin
    random.seed()

    max_packets = 2000
    numPackets = random.randrange(max_packets + 1)

    bitstream, indexes = bitstream_gen(numPackets, 10 ** 6)

    print(numPackets)
    print(sorted(indexes))
    print(len(bitstream))

    with open("Text Files/random_bits_10kb.txt", "w") as f:
        f.write(bitstream)
else:
    from Python.Modules.helpers import hex2bin
