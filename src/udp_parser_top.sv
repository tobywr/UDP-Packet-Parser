module udp_parser_top (
    input logic clk,
    input logic rst_n,

    input logic [15:0] target_port,

    input logic [7:0] data_in,
    input logic packet_start,
    input logic data_valid_in,
    output logic ready_out,

    output logic [7:0] payload_data_out,
    output logic payload_valid_out,
    output logic payload_last,
    input logic ready_in,

    output logic [15:0] src_port,
    output logic [15:0] dst_port,
    output logic [15:0] length,
    output logic header_done
);

  //defining internal wires
  logic parse_enable, fwd_enable, drop_enable;
  logic [15:0] udp_length_wire, checksum_wire;
  logic port_match_wire, checksum_ok_wire;
  logic packet_last_wire;
  logic [15:0] raw_checksum;
  //skip checksum as not implemented correctly yet.
  assign checksum_ok_wire = 1'b1;

  //INSTANTATE ALL LOGIC
  control_FSM u_control_FSM (
      .clk(clk),
      .rst_n(rst_n),
      .data_valid_in(data_valid_in),
      .packet_last(packet_last_wire),
      .header_done(header_done),
      .port_match(port_match_wire),
      .checksum_ok(checksum_ok_wire),
      .parse_enable(parse_enable),
      .fwd_enable(fwd_enable),
      .drop_enable(drop_enable),
      .counter_rst(counter_rst),
      .counter_enable(counter_enable),
      .packet_start(packet_start)
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
      .header_done(header_done)
  );

  udp_header_parser u_udp_header_parser (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(data_in),
      .data_valid(data_valid_in),
      .ready_out(ready_out),
      .target_port(target_port),
      .parse_enable(parse_enable),
      .src_port(src_port),
      .dst_port(dst_port),
      .port_match(port_match_wire),
      .length(udp_length_wire),
      .checksum(raw_checksum),
      .header_done(header_done)
  );
  
  packet_byte_counter u_packet_byte_counter (
      .clk(clk),
      .rst_n(rst_n),
      .counter_rst(counter_rst),
      .counter_enable(counter_enable),
      .udp_length(udp_length_wire),
      .packet_last(packet_last_wire)
  );

  assign length = udp_length_wire;
endmodule
