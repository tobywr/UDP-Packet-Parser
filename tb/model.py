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