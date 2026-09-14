from udp_env import start_clock, reset_dut, send_packet, monitor_output, wiggle_ready
from model import parse_udp_packet, make_packet, expected_stream
import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, ReadOnly, NextTimeStep, ClockCycles

@cocotb.test()
async def test_send_one_packet(dut):
    await start_clock(dut)
    await reset_dut(dut)
    target_port = 1234
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1

    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    packet = [0xC0, 0x00, 0x04, 0xD2, 0x00, 0x11, 0x00, 0x00, 0x54, 0x45, 0x53, 0x54, 0x20, 0x54, 0x45, 0x53, 0x54]
    golden_returned = parse_udp_packet(packet, target_port)

    await send_packet(dut, packet)

    await ClockCycles(dut.clk, 10)

    assert dut.src_port.value == golden_returned["src_port"]
    assert dut.dst_port.value == golden_returned["dst_port"]
    assert dut.length.value == golden_returned["length"]
    assert bytes(recieved) == golden_returned["payload"]
    assert lasts == expected_stream([packet], target_port)[1], f"tlast flags: {lasts}"


@cocotb.test()
async def test_mismatch_port_drop(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    target_port = 1234
    dut.m_axis_tready.value = 1
    recieved = []
    cocotb.start_soon(monitor_output(dut, recieved))

    #dst port = 9999 doesnt match target
    packet = [0xC1, 0x01, 0x27, 0x0F, 0x00, 0x0D, 0x00, 0x00] + list(b"HELLO")
    golden_returned = parse_udp_packet(packet, target_port)

    await send_packet(dut, packet)
    await ClockCycles(dut.clk, 10)
    assert bytes(recieved) == golden_returned["payload"], f"dropped packet leaked bytes: {recieved}"

@cocotb.test()
async def test_zero_length_payload(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    target_port = 1234
    dut.m_axis_tready.value = 1

    recieved = []
    cocotb.start_soon(monitor_output(dut, recieved))

    packet = [0x00, 0x01, 0x04, 0xD2, 0x00, 0x08, 0x00, 0x00]
    golden_returned = parse_udp_packet(packet, target_port)

    await send_packet(dut, packet)
    await ClockCycles(dut.clk, 20)
    assert dut.src_port.value == golden_returned["src_port"]
    assert dut.dst_port.value == golden_returned["dst_port"]
    assert dut.length.value == golden_returned["length"]
    assert bytes(recieved) == golden_returned["payload"], f"got unexpected bytes for a zero-length packet: {recieved}"

@cocotb.test()
async def test_backpressure_mid_payload(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    packet = [0xC0, 0x00, 0x04, 0xD2, 0x00, 0x11, 0x00, 0x00, 0x54, 0x45, 0x53, 0x54, 0x20, 0x54, 0x45, 0x53, 0x54]
    stats = {"stall_cycles": 0}
    wiggler = cocotb.start_soon(wiggle_ready(dut, stats))

    await send_packet(dut, packet)
    await ClockCycles(dut.clk, 10)

    assert bytes(recieved) == b"TEST TEST", f"got {bytes(recieved)!r}"

    wiggler.cancel()
    dut.m_axis_tready.value = 1
    assert stats["stall_cycles"] > 0, "backpressure never exercised."
    assert lasts == [0] * 8 + [1], f"tlast flags: {lasts}"

@cocotb.test()
async def test_back_to_back_payloads(dut):
    await start_clock(dut)
    await reset_dut(dut)

    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    packet1 = [0x00, 0x01, 0x04, 0xD2, 0x00, 0x0D, 0x00, 0x00] + list(b"FIRST")
    packet2 = [0x00, 0x02, 0x04, 0xD2, 0x00, 0x0F, 0x00, 0x00] + list(b"SECOND!")
    await send_packet(dut, packet1)
    await send_packet(dut, packet2)
    await ClockCycles(dut.clk, 10)

    assert bytes(recieved) == b"FIRSTSECOND!", f"got {bytes(recieved)!r}"
    assert lasts == [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1], f"tlast flags: {lasts}"

@cocotb.test()
async def test_drop_then_forward_no_gap(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    packets = [make_packet(1, 9999, b"HELLO"), make_packet(2, 1234, b"WORLD")]
    for p in packets:
        await send_packet(dut, p)
    await ClockCycles(dut.clk, 10)

    exp_data, exp_lasts = expected_stream(packets, 1234)
    assert bytes(recieved) == exp_data, f"got {bytes(recieved)!r}"
    assert lasts == exp_lasts, f"tlast flags: {lasts}"


@cocotb.test()
async def test_zero_length_then_forward_no_gap(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    packets = [make_packet(1, 1234, b""), make_packet(2, 1234, b"AFTER")]
    for p in packets:
        await send_packet(dut, p)
    await ClockCycles(dut.clk, 10)

    exp_data, exp_lasts = expected_stream(packets, 1234)
    assert bytes(recieved) == exp_data, f"got {bytes(recieved)!r}"
    assert lasts == exp_lasts, f"tlast flags: {lasts}"


@cocotb.test()
async def test_one_byte_payload(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    await send_packet(dut, make_packet(1, 1234, b"X"))
    await ClockCycles(dut.clk, 10)
    assert bytes(recieved) == b"X" and lasts == [1], f"got {bytes(recieved)!r}, tlast {lasts}"


@cocotb.test()
async def test_backpressure_on_last_byte(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    async def stall_on_last():
        await ClockCycles(dut.clk, 10)        # 8 header + 'A' + 'B' have gone by
        await FallingEdge(dut.clk)
        dut.m_axis_tready.value = 0
        await ClockCycles(dut.clk, 3)
        await FallingEdge(dut.clk)
        dut.m_axis_tready.value = 1
    cocotb.start_soon(stall_on_last())

    await send_packet(dut, make_packet(1, 1234, b"ABC"))
    await ClockCycles(dut.clk, 10)
    assert bytes(recieved) == b"ABC" and lasts == [0, 0, 1], f"got {bytes(recieved)!r}, tlast {lasts}"


@cocotb.test()
async def test_upstream_valid_gaps(dut):
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))

    packets = [make_packet(1, 1234, b"GAPPY PAYLOAD"), make_packet(2, 1234, b"MORE")]
    for p in packets:
        await send_packet(dut, p, valid_gap_prob=0.4)
    await ClockCycles(dut.clk, 10)

    exp_data, exp_lasts = expected_stream(packets, 1234)
    assert bytes(recieved) == exp_data, f"got {bytes(recieved)!r}"
    assert lasts == exp_lasts, f"tlast flags: {lasts}"


@cocotb.test()
async def test_random_packets(dut):
    random.seed(1)
    await start_clock(dut)
    await reset_dut(dut)
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved, lasts = [], []
    cocotb.start_soon(monitor_output(dut, recieved, lasts))
    stats = {"stall_cycles": 0}
    wiggler = cocotb.start_soon(wiggle_ready(dut, stats))

    packets = []
    for _ in range(100): #only 100, can change to far more.
        dst = 1234 if random.random() < 0.6 else random.choice([0, 80, 9999, 65535])
        n = random.choice([0, 1, 2, 7, 8, 9, 31, 64, 200])
        packets.append(make_packet(random.randrange(65536), dst, bytes(random.randrange(256) for _ in range(n))))
    for p in packets:
        await send_packet(dut, p, valid_gap_prob=0.2)
    await ClockCycles(dut.clk, 50)
    wiggler.cancel()
    dut.m_axis_tready.value = 1

    exp_data, exp_lasts = expected_stream(packets, 1234)
    assert bytes(recieved) == exp_data, "payload mismatch in random regression"
    assert lasts == exp_lasts, "tlast mismatch in random regression"