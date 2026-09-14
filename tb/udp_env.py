import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge

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
    await FallingEdge(dut.clk)          

async def send_packet(dut, packet, valid_gap_prob=0.0):
    for i, byte in enumerate(packet):
        while random.random() < valid_gap_prob:
            dut.s_axis_tvalid.value = 0
            dut.s_axis_tuser.value = 0
            await FallingEdge(dut.clk)
        dut.s_axis_tdata.value = byte
        dut.s_axis_tvalid.value = 1
        dut.s_axis_tuser.value = 1 if i == 0 else 0

        while True:
            await RisingEdge(dut.clk)
            if dut.s_axis_tready.value == 1:
                break

        await FallingEdge(dut.clk)      
    dut.s_axis_tvalid.value = 0
    dut.s_axis_tuser.value = 0

async def monitor_output(dut, recieved, lasts=None):
    while True:
        await RisingEdge(dut.clk)
        if dut.m_axis_tvalid.value == 1 and dut.m_axis_tready.value == 1:
            recieved.append(int(dut.m_axis_tdata.value))
            if lasts is not None:
                lasts.append(int(dut.m_axis_tlast.value))

async def wiggle_ready(dut, stats):
    while True:
        await FallingEdge(dut.clk) 
        ready = random.choice([0, 0, 1, 1, 1])
        dut.m_axis_tready.value = ready
        if ready == 0:
            stats["stall_cycles"] += 1