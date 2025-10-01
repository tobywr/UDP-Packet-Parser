module udp_parser_top (
    input logic clk,
    input logic rst_n,

    input logic [15:0] target_port,

    input logic [7:0] data_in,
    input logic data_valid_in,
    output logic ready_out,

    output logic [7:0] payload_data_out,
    output logic payload_valid_out,
    output logic payload_last,
    input logic ready_in,

    output logic [15:0] src_port,
    output logic [15:0] dst_port,
    output logic [15:0] length,
    output logic header_done,

    output logic [15:0] latched_cycle_count
);

  //defining internal wires
  logic parse_enable, latch_outputs, fwd_enable, drop_enable;
  logic [15:0] udp_length_wire, checksum_wire;
  logic port_match_wire;
  logic last_in_wire;
  logic [15:0] global_byte_count;
  logic checksum_ok = 1'b1;  //for the time being, checksum is disabled.
  logic is_first_byte;
  assign is_first_byte = counter_rst && data_valid_in;
  logic header_done_wire;
  assign length = udp_length_wire;
  assign header_done = header_done_wire;

  //INSTANTATE ALL LOGIC
  control_FSM u_control_FSM (
      .clk(clk),
      .rst_n(rst_n),
      .data_valid_in(data_valid_in),
      .last_in(payload_last),
      .header_done(header_done_wire),
      .port_match(port_match_wire),
      .checksum_ok(checksum_ok),
      .parse_enable(parse_enable),
      .latch_outputs(latch_outputs),
      .fwd_enable(fwd_enable),
      .drop_enable(drop_enable),
      .counter_rst(counter_rst),
      .counter_enable(counter_enable)
  );

  payload_forwarder u_payload_forwarder (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(data_in),
      .data_valid_in(data_valid_in),
      .ready_out(ready_out),
      .fwd_enable(fwd_enable),
      .drop_enable(drop_enable),
      .udp_length(udp_length_wire),
      .payload_data_out(payload_data_out),
      .payload_valid_out(payload_valid_out),
      .payload_last(payload_last),
      .ready_in(ready_in),
      .header_done(header_done_wire)
  );

  udp_header_parser u_udp_header_parser (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(data_in),
      .data_valid(data_valid_in),
      .ready_out(ready_out),
      .target_port(target_port),
      .parse_enable(parse_enable),
      .latch_outputs(latch_outputs),
      .src_port(src_port),
      .dst_port(dst_port),
      .port_match(port_match_wire),
      .length(udp_length_wire),
      .checksum(checksum_wire),
      .header_done(header_done_wire)
  );

  cycle_counter u_cycle_counter (
      .clk(clk),
      .rst_n(rst_n),
      .start_counter(is_first_byte),
      .stop_counter(payload_last),
      .cycle_count(latched_cycle_count),
      .is_counting()
  );

endmodule
