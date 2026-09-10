"""Read PNG/JPEG dimensions without decoding or changing official reference bytes."""
import struct

def dimensions(data: bytes) -> list[int]:
    if data.startswith(b'\x89PNG\r\n\x1a\n'):
        return list(struct.unpack('>II', data[16:24]))
    if not data.startswith(b'\xff\xd8'):
        raise ValueError('Expected PNG or JPEG reference')
    i = 2
    while i < len(data):
        if data[i] != 0xff:
            raise ValueError('Invalid JPEG marker')
        while data[i] == 0xff:
            i += 1
        marker = data[i]
        i += 1
        if marker in (0xd8, 0xd9) or 0xd0 <= marker <= 0xd7:
            continue
        length = struct.unpack('>H', data[i:i+2])[0]
        if marker in (0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf):
            height, width = struct.unpack('>HH', data[i+3:i+7])
            return [width, height]
        if marker == 0xda:
            break
        i += length
    raise ValueError('No JPEG dimensions found')
