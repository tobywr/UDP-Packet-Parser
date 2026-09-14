def parse_udp_packet(packet, target_port):

    src_port = (packet[0] << 8 ) | packet[1]
    dst_port = (packet[2] << 8) | packet[3]
    length = (packet[4] << 8) | packet[5]

    port_match = (dst_port == target_port)

    if length > 8:
        payload_length = length - 8
    else:
        payload_length = 0

    payload = packet[8:8 + payload_length] if port_match else []

    return {
        "src_port": src_port,
        "dst_port": dst_port,
        "port_match": port_match,
        "payload": bytes(payload),
        "length": length
    }

def make_packet(src_port, dst_port, payload, checksum=0):
    length = 8 + len(payload)
    return [src_port >> 8, src_port & 0xFF, dst_port >> 8, dst_port & 0xFF,
            length >> 8, length & 0xFF, checksum >> 8, checksum & 0xFF] + list(payload)

def expected_stream(packets, target_port):
    """golden model for a sequence: (concatenated payload bytes, tlast flags)."""
    data, lasts = b"", []
    for p in packets:
        payload = parse_udp_packet(p, target_port)["payload"]
        if payload:
            data += payload
            lasts += [0] * (len(payload) - 1) + [1]
    return data, lasts