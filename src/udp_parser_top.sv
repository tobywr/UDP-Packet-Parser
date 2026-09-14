module udp_parser_top (
    input logic clk,
    input logic rst_n,

    input logic [15:0] target_port,

    input logic [7:0] s_axis_tdata,
    input logic s_axis_tuser,  //SOF
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
  logic port_match_wire, has_payload_wire, packet_done_wire;
  logic [15:0] raw_checksum;
  logic s_beat, header_done_int;
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) header_done <= 1'b0;
    else header_done <= header_done_int;
  //definition of "a byte is consumed"
  assign s_beat = s_axis_tvalid && s_axis_tready;



  //INSTANTATE ALL LOGIC
  control_FSM u_control_FSM (
      .clk         (clk),
      .rst_n       (rst_n),
      .s_beat      (s_beat),
      .packet_start(s_axis_tuser),
      .header_done (header_done_int),
      .port_match  (port_match_wire),
      .has_payload (has_payload_wire),
      .packet_done (packet_done_wire),
      .parse_enable(parse_enable),
      .fwd_enable  (fwd_enable),
      .drop_enable (drop_enable)
  );

  udp_header_parser u_udp_header_parser (
      .clk         (clk),
      .rst_n       (rst_n),
      .data_in     (s_axis_tdata),
      .s_beat      (s_beat),
      .packet_start(s_axis_tuser),
      .target_port (target_port),
      .parse_enable(parse_enable),
      .src_port    (src_port),
      .dst_port    (dst_port),
      .port_match  (port_match_wire),
      .length      (length),
      .has_payload (has_payload_wire),
      .checksum    (raw_checksum),
      .header_done (header_done_int)
  );

  payload_forwarder u_payload_forwarder (
      .clk              (clk),
      .rst_n            (rst_n),
      .data_in          (s_axis_tdata),
      .data_valid_in    (s_axis_tvalid),
      .packet_start     (s_axis_tuser),
      .ready_out        (s_axis_tready),
      .fwd_enable       (fwd_enable),
      .drop_enable      (drop_enable),
      .header_done      (header_done_int),
      .udp_length       (length),
      .payload_data_out (m_axis_tdata),
      .payload_valid_out(m_axis_tvalid),
      .payload_last     (m_axis_tlast),
      .packet_done      (packet_done_wire),
      .ready_in         (m_axis_tready)
  );
endmodule
