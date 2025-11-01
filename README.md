# UDP-Packet-Parser

This is an example of a simple implementation of a UDP packet parser utilizing SystemVerilog. This design parses UDP headers, validates the packet based on checksum (WIP) and destination port, and forwards / drops payloads.

### Features

- **Header Parsing:** Extracts source port, destination port and payload length from UDP header.
- **Port Filtering:** Only forwards payload packets matching the configured target port.


## Architecutre

The design consists of five main modules :

1. `udp_parser_top`
   
   Top-Level module for instantiating and connecting all sub-modules.

2. `control_FSM`

    FSM controlling packet pipeline:
    - `IDLE` : Waiting or packet
    - `PARSING_HEADER` : Recieving + Parsing 8-Byte UDP header
    - `CHECK_HEADER` : Validating port match
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

5. `packet_byte_counter`
   
   Handles payload_last signal.

6. `udp_parser_synth_top`
   
   Top level file for Synthesis. 

## Top level signals
###  Inputs

- `clk` : System clock
- `rst_n` : Active high reset signal.
- `targe_port` : pre-defined destination port for packet data. (16-bit)
- `data_in` : UDP packet input data stream. (8-bit)
- `data_valid_in` : Input data valid singal.
- `ready_in` : Downstream ready signal.

### Outputs

- `ready_out` : Ready to accept input data.
- `payload_data_out` : Parsed payload data (8-bit)
- `payload_valid_out` : Signal to state that payload data is correct.
- `payload_last` : Asserted on last byte of payload being parsed.
- `src_port` : Source port of data. (16-bit)
- `dst_port` : Destination port of data. (16-bit)
- `length` : Length of the payload data (16-bit)
- `header_done` : Asserted once header has been parsed
- `latched_cycle_count` : Cycle count of entire process. (16-bit)    

## Simulation

This Repo contains a SystemVerilog test bench (`udp_parser_TB.sv`) that : 
- Generates a test UDP packet with "TEST TEST" payload
- Configures target port to 1234
- Drives packet through the parser
- displays recieved payload and performance metrics in console.

### Expected Output

```
Driving data packet
TEST TEST
Test finished
Source Port = 49152
Destination Port = 1234
Length = 17
Cycle count = 17
Finished.
```

### Packet Format

```
Bytes 0-1: Source port (big-endian)
Bytes 2-3: Destination port (big-endian)
Bytes 4-5: Length (Big-Endian, include both header + payload length)
Bytes 6-7: Checksum (Big-Endian)
Bytes 8-N: Payload data
```

### Current Limitations
- Checksum validation currently not implemented , hardcoded to pass (`checksum_ok = 1'b1`)
- Single packet processing (No concurrent packet handling)
- `ready_in` is hardcoded to `1'b1`.


## Project Structure

```
.
|---src/
|   |--payload_forwarder.sv
|   |--control_FSM.sv
|   |--cycle_counter.sv
|   |--udp_header_parser.sv
|   |--udp_parser_top.sv
|   |--packet_byte_counter.sv
|
|---sim/
|   |-udp_parser_TB.sv
|
|---README.md
|
|---constraints/
|   |-constraints.xdc