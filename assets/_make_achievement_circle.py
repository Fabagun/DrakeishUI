"""Decode Achievement_window.blp and write circular-alpha TGA."""
import struct, math, os
SRC = r"D:\WOTLKCustom\Interface\AddOns\DrakeishUI\assets\Achievement_window.blp"
OUT = r"D:\WOTLKCustom\Interface\AddOns\DrakeishUI\assets\Achievement_window_circle.tga"

def unpack565(c):
    r = ((c >> 11) & 31) * 255 // 31
    g = ((c >> 5) & 63) * 255 // 63
    b = (c & 31) * 255 // 31
    return r, g, b

def decode_dxt5_block(block):
    a0, a1 = block[0], block[1]
    bits = int.from_bytes(block[2:8], "little")
    alphas = [0] * 8
    alphas[0], alphas[1] = a0, a1
    if a0 > a1:
        for i in range(1, 7):
            alphas[i + 1] = ((7 - i) * a0 + i * a1) // 7
    else:
        for i in range(1, 5):
            alphas[i + 1] = ((5 - i) * a0 + i * a1) // 5
        alphas[6], alphas[7] = 0, 255
    aidx = [(bits >> (3 * i)) & 0x7 for i in range(16)]
    c0 = struct.unpack_from("<H", block, 8)[0]
    c1 = struct.unpack_from("<H", block, 10)[0]
    colors = [unpack565(c0), unpack565(c1), None, None]
    colors[2] = tuple((2 * colors[0][i] + colors[1][i]) // 3 for i in range(3))
    colors[3] = tuple((colors[0][i] + 2 * colors[1][i]) // 3 for i in range(3))
    cbits = struct.unpack_from("<I", block, 12)[0]
    pixels = []
    for i in range(16):
        r, g, b = colors[(cbits >> (2 * i)) & 0x3]
        pixels.append((r, g, b, alphas[aidx[i]]))
    return pixels

def decode_dxt5(blob, width, height):
    out = [(0, 0, 0, 0)] * (width * height)
    bw, bh = (width + 3) // 4, (height + 3) // 4
    off = 0
    for by in range(bh):
        for bx in range(bw):
            pix = decode_dxt5_block(blob[off:off + 16]); off += 16
            for py in range(4):
                for px in range(4):
                    x, y = bx * 4 + px, by * 4 + py
                    if x < width and y < height:
                        out[y * width + x] = pix[py * 4 + px]
    return out

def write_tga(path, width, height, pixels):
    header = bytearray(18)
    header[2] = 2
    header[12] = width & 0xFF; header[13] = (width >> 8) & 0xFF
    header[14] = height & 0xFF; header[15] = (height >> 8) & 0xFF
    header[16] = 32; header[17] = 0x28
    body = bytearray()
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[y * width + x]
            body += bytes((b, g, r, a))
    open(path, "wb").write(header + body)

data = open(SRC, "rb").read()
assert data[:4] == b"BLP2"
width = struct.unpack_from("<I", data, 12)[0]
height = struct.unpack_from("<I", data, 16)[0]
mip0_off = struct.unpack_from("<I", data, 20)[0]
mip0_size = struct.unpack_from("<I", data, 84)[0]
print(f"BLP2 {width}x{height} mip0={mip0_off}+{mip0_size}")
pixels = decode_dxt5(data[mip0_off:mip0_off + mip0_size], width, height)
cx = cy = (width - 1) / 2.0
rad = min(width, height) / 2.0
masked = []
for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[y * width + x]
        dist = math.hypot(x - cx, y - cy)
        if dist > rad: ma = 0
        elif dist > rad - 1.0: ma = int(a * (rad - dist))
        else: ma = a
        masked.append((r, g, b, ma))
write_tga(OUT, width, height, masked)
print("wrote", OUT, os.path.getsize(OUT))
