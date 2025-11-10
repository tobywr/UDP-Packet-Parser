module udp_parser_synth_top (
    input logic clk,
    input logic rst_n,
    input logic [7:0] data_in,
    input logic data_valid_in,
    input logic packet_start,
    input logic ready_in,
    input logic [15:0] target_port,

    output logic [7:0] payload_data_out,
    output logic payload_valid_out,
    output logic payload_last,
    output logic ready_out,
    output logic [15:0] dst_port,
    output logic header_done
);
  udp_parser_top u (
    .clk(clk),
    .rst_n(rst_n),
    .target_port(target_port),
    .data_in(data_in),
    .packet_start(packet_start),
    .data_valid_in(data_valid_in),
    .ready_in(ready_in),
    .payload_data_out(payload_data_out),
    .payload_valid_out(payload_valid_out),
    .payload_last(payload_last),
    .ready_out(ready_out),
    .src_port(),
    .dst_port(dst_port),
    .length(),
    .header_done(header_done)
  );
endmodule
