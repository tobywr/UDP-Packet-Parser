import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep

async def start_clock(dut, period_ns=10):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

async def reset_dut(dut, cycles=5):
    dut.rst_n.value = 0
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tuser.value = 0
    dut.m_axis_tready.value = 0
    for i in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

async def send_packet(dut, packet):
    for i, byte in enumerate(packet):
        dut.s_axis_tdata.value = byte
        dut.s_axis_tvalid.value = 1
        if i == 0:
            dut.s_axis_tuser.value = 1
        else :
            dut.s_axis_tuser.value = 0

        while True:
            await RisingEdge(dut.clk)
            await ReadOnly()
            if dut.s_axis_tready.value == 1:
                break

        await NextTimeStep()
        dut.s_axis_tvalid.value = 0

async def monitor_output(dut, recieved):
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        if dut.m_axis_tvalid.value == 1 and dut.m_axis_tready.value == 1:
            recieved.append(int(dut.m_axis_tdata.value))

async def wiggle_ready(dut, stats):
    while True:
        ready = random.choice([0, 0, 1, 1, 1])
        dut.m_axis_tready.value = ready
        if ready == 0:
            stats["stall_cycles"] += 1
        await RisingEdge(dut.clk)