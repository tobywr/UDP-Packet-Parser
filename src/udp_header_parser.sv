`timescale 1ns / 1ps
module udp_header_parser (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [ 7:0] data_in,
    input  logic        s_beat,
    input  logic        packet_start,
    input  logic [15:0] target_port,
    input  logic        parse_enable,
    output logic [15:0] src_port,
    output logic [15:0] dst_port,
    output logic        port_match,
    output logic [15:0] length,
    output logic        has_payload,
    output logic [15:0] checksum,
    output logic        header_done
);

  //internal logic
  logic [2:0] byte_counter, idx;

  //SOF overrides counter so new packet arrives after header_done indexed from 0 immediately
  assign idx = packet_start ? 3'd0 : byte_counter;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) byte_counter <= 3'd0;
    else if (!parse_enable) byte_counter <= 3'd0;
    else if (s_beat) byte_counter <= (idx == 3'd7) ? 3'd7 : idx + 3'd1;
  end

  always_ff @(posedge clk or negedge rst_n) begin : header_accumulation
    if (!rst_n) begin
      src_port <= 16'd0;
      dst_port <= 16'd0;
      length   <= 16'd0;
      checksum <= 16'd0;
    end else if (parse_enable && s_beat) begin
      case (idx)
        3'd0: src_port[15:8] <= data_in;
        3'd1: src_port[7:0] <= data_in;
        3'd2: dst_port[15:8] <= data_in;
        3'd3: dst_port[7:0] <= data_in;
        3'd4: length[15:8] <= data_in;
        3'd5: length[7:0] <= data_in;
        3'd6: checksum[15:8] <= data_in;
        3'd7: checksum[7:0] <= data_in;
      endcase
    end
  end

  assign header_done = parse_enable && s_beat && (idx == 3'd7);
  assign port_match  = (dst_port == target_port);
  assign has_payload = (length > 16'd8);

endmodule
