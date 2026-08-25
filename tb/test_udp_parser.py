from udp_env import start_clock, reset_dut, send_packet, monitor_output, wiggle_ready
from model import parse_udp_packet
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep, ClockCycles

@cocotb.test()
async def test_send_one_packet(dut):
    await start_clock(dut)
    await reset_dut(dut)
    target_port = 1234
    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1

    recieved = []
    cocotb.start_soon(monitor_output(dut, recieved))

    packet = [0xC0, 0x00, 0x04, 0xD2, 0x00, 0x11, 0x00, 0x00, 0x54, 0x45, 0x53, 0x54, 0x20, 0x54, 0x45, 0x53, 0x54]
    golden_returned = parse_udp_packet(packet, target_port)

    await send_packet(dut, packet)

    await ClockCycles(dut.clk, 10)

    assert dut.src_port.value == golden_returned["src_port"]
    assert dut.dst_port.value == golden_returned["dst_port"]
    assert dut.length.value == golden_returned["length"]
    assert bytes(recieved) == golden_returned["payload"]


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
    recieved = []
    cocotb.start_soon(monitor_output(dut, recieved))

    packet = [0xC0, 0x00, 0x04, 0xD2, 0x00, 0x11, 0x00, 0x00, 0x54, 0x45, 0x53, 0x54, 0x20, 0x54, 0x45, 0x53, 0x54]
    stats = {"stall_cycles": 0}
    wiggler = cocotb.start_soon(wiggle_ready(dut, stats))

    await send_packet(dut, packet)
    await ClockCycles(dut.clk, 10)

    assert bytes(recieved) == b"TEST TEST", f"got {bytes(recieved)!r}"

    wiggler.cancel()
    dut.m_axis_tready.value = 1
    assert stats["stall_cycles"] > 0, "backpressure never exercised."

@cocotb.test()
async def test_back_to_back_payloads(dut):
    await start_clock(dut)
    await reset_dut(dut)

    dut.target_port.value = 1234
    dut.m_axis_tready.value = 1
    recieved = []
    cocotb.start_soon(monitor_output(dut, recieved))

    packet1 = [0x00, 0x01, 0x04, 0xD2, 0x00, 0x0D, 0x00, 0x00] + list(b"FIRST")
    packet2 = [0x00, 0x02, 0x04, 0xD2, 0x00, 0x0F, 0x00, 0x00] + list(b"SECOND!")
    await send_packet(dut, packet1)
    await send_packet(dut, packet2)
    await ClockCycles(dut.clk, 10)

    assert bytes(recieved) == b"FIRSTSECOND!", f"got {bytes(recieved)!r}"




