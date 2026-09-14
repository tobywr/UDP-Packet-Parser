# UDP-Packet-Parser with Axi-Stream ports

This is an example of an implementation of a UDP packet parser utilizing SystemVerilog. This design parses UDP headers, validates the packet based on destination port, and forwards / drops payloads. Currently operates on an 8-bit datapath (64-bit WIP).

### Features

- **Header Parsing:** Extracts source port, destination port and payload length from UDP header.
- **Port Filtering:** Only forwards payload packets matching the configured target port.


## Architecture

The design consists of four main modules :

1. `udp_parser_top`
   
   Top-Level module for instantiating and connecting all sub-modules. Contains Axi-Stream top ports.

2. `control_FSM`

    FSM controlling packet pipeline:
    - `IDLE` : Waiting for packet
    - `PARSING_HEADER` : Recieving + Parsing 8-Byte UDP header
    - `FORWARD_PAYLOAD` : Streaming valid payload bytes
    - `DROP_PAYLOAD` : Silently discarding invalid / corrupt payload packets.
  
3. `udp_header_parser`

    Parses incoming byte stream into the correct UDP header fields:

    - Accumulated 8 header bytes
    - Extracts source port, destination port and checksum
    - Validates destination port against pre-defined target port.

4. `payload_forwarder`

    Manages payload byte forwarding

    - Forwards payload bytes when enabled
    - Contains skid buffer to register outputs (reducing critical path)


## Top level signals
### Inputs

- `clk` : System clock
- `rst_n` : Active-low reset signal.
- `target_port` : pre-defined destination port for packet data. (16-bit)
- `s_axis_tdata` : UDP packet input data stream. (8-bit)
- `s_axis_tvalid` : Input data valid signal.
- `m_axis_tready` : Downstream ready signal.
- `s_axis_tuser` : start of frame / packet start signal

### Outputs

- `m_axis_tdata` : Parsed payload data (8-bit)
- `m_axis_tvalid` : Signal to state that payload data is correct.
- `m_axis_tlast` : Asserted on last byte of payload being parsed.
- `src_port` : Source port of data. (16-bit)
- `dst_port` : Destination port of data. (16-bit)
- `length` : Length of the payload data (16-bit)
- `header_done` : Asserted once header has been parsed
- `s_axis_tready` : backpressure signal to upstream

## Simulation (Python CocoTB)

This repo also contains a python testbench using cocotb that:
- Generates single udp packet
- Validates backpressure
- Validates a zero-length payload produces no output
- Validates packets are dropped if the ports do not match
- Generates random packets and validates integrity.
It utilses a golden model (`model.py`) to compare the output from the DUT against.

### How to run CocoTB testbench
Only tested on linux (Ubuntu) so far.

1. Clone repo to a working directory.
2. Install all dependancies : cocotb `pip install cocotb`, Icarus Verilog (simulator) `sudo apt install iverilog`, make, (optional) GTKWave for waveform viewing `sudo apt install gtkwave`.
3. enter the tb/ directory
4. run `make SIM=icarus` to compile all and run.
OPTIONAL: waveform viewing:
5. run `make SIM=icarus WAVES=1`
6. view wave with `gtkwave sim_build/udp_parser_top.fst`

### Implementation Results (Zynq 7000 series)
200MHz Clock, +0.47ns WNS , out-of-context, 40% I/O budgets.
Utilization: 78 LUTs, 108FFs.


### Packet Format

```
Bytes 0-1: Source port (big-endian)
Bytes 2-3: Destination port (big-endian)
Bytes 4-5: Length (Big-Endian, include both header + payload length)
Bytes 6-7: Checksum (Big-Endian)
Bytes 8-N: Payload data
```

## Project Structure

```
.
|---src/
|   |--payload_forwarder.sv
|   |--control_FSM.sv
|   |--udp_header_parser.sv
|   |--udp_parser_top.sv
|
|---sim/
|   |-udp_parser_TB.sv
|
|---tb/
|   |-Makefile
|   |-model.py
|   |-test_udp_parser.py
|   |-udp_env.py   
|
|---README.md
|
|---constraints/
|   |-constraints.xdc