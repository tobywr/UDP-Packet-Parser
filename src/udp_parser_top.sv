module udp_parser_top (
    input logic clk,
    input logic rst_n,

    input logic [15:0] target_port,

    input logic [7:0] s_axis_tdata,
    input logic s_axis_tuser,
    input logic s_axis_tvalid,
    output logic s_axis_tready,

    output logic [7:0] m_axis_tdata,
    output logic m_axis_tvalid,
    output logic m_axis_tlast,
    input logic m_axis_tready,

    output logic [15:0] src_port,
    output logic [15:0] dst_port,
    output logic [15:0] length,
    output logic header_done
);

  //defining internal wires
  logic parse_enable, fwd_enable, drop_enable;
  logic [15:0] udp_length_wire;
  logic port_match_wire, checksum_ok_wire;
  logic [15:0] raw_checksum;
  logic packet_done_wire;
  //skip checksum as not implemented correctly yet.
  assign checksum_ok_wire = 1'b1;

  //INSTANTATE ALL LOGIC
  control_FSM u_control_FSM (
      .clk(clk),
      .rst_n(rst_n),
      .data_valid_in(s_axis_tvalid),
      .packet_last(packet_done_wire),
      .header_done(header_done),
      .port_match(port_match_wire),
      .checksum_ok(checksum_ok_wire),
      .parse_enable(parse_enable),
      .fwd_enable(fwd_enable),
      .drop_enable(drop_enable),
      .packet_start(s_axis_tuser)
  );

  payload_forwarder u_payload_forwarder (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(s_axis_tdata),
      .data_valid_in(s_axis_tvalid),
      .ready_out(s_axis_tready),
      .fwd_enable(fwd_enable),
      .drop_enable(drop_enable),
      .udp_length(udp_length_wire),
      .payload_data_out(m_axis_tdata),
      .payload_valid_out(m_axis_tvalid),
      .payload_last(m_axis_tlast),
      .packet_done(packet_done_wire),
      .ready_in(m_axis_tready),
      .header_done(header_done)
  );

  udp_header_parser u_udp_header_parser (
      .clk(clk),
      .rst_n(rst_n),
      .data_in(s_axis_tdata),
      .data_valid(s_axis_tvalid),
      .target_port(target_port),
      .parse_enable(parse_enable),
      .src_port(src_port),
      .dst_port(dst_port),
      .port_match(port_match_wire),
      .length(udp_length_wire),
      .checksum(raw_checksum),
      .header_done(header_done)
  );
  
  assign length = udp_length_wire;
endmodule
