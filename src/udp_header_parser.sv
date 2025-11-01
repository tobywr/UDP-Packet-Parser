`timescale 1ns / 1ps
module udp_header_parser (
    input  logic        clk,
    input  logic        rst_n,
    //data input stream
    input  logic [ 7:0] data_in,
    input  logic        data_valid,
    input  logic        ready_out,
    input  logic [15:0] target_port,
    //control interface (from FSM)
    input  logic        parse_enable,
    //parsed header outputs
    output logic [15:0] src_port,
    output logic [15:0] dst_port,
    output logic        port_match,
    output logic [15:0] length,
    output logic [15:0] checksum,
    output logic        header_done
);

  //internal logic
  logic [3:0] byte_counter;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      byte_counter <= 4'd0;
    end else if(!parse_enable) begin
       byte_counter <= 4'd0;
    end else if (data_valid) begin
       if (byte_counter < 4'd7) byte_counter <= byte_counter + 1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin : header_accumulation
    if (!rst_n) begin
      src_port <= 16'd0;
      dst_port <= 16'd0;
      length   <= 16'd0;
      checksum <= 16'd0;
    end else if (parse_enable && data_valid && byte_counter <= 4'd7) begin
      case (byte_counter)
        4'd0: src_port[15:8] <= data_in;
        4'd1: src_port[7:0] <= data_in;
        4'd2: dst_port[15:8] <= data_in;
        4'd3: dst_port[7:0] <= data_in;
        4'd4: length[15:8] <= data_in;
        4'd5: length[7:0] <= data_in;
        4'd6: checksum[15:8] <= data_in;
        4'd7: checksum[7:0] <= data_in;
      endcase
    end
  end

  assign header_done = (byte_counter == 4'd7) && parse_enable && data_valid;
  assign port_match  = (dst_port == target_port);

endmodule
