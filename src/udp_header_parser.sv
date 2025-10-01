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
    input  logic        latch_outputs,
    //parsed header outputs
    output logic [15:0] src_port,
    output logic [15:0] dst_port,
    output logic        port_match,
    output logic [15:0] length,
    output logic [15:0] checksum,
    output logic        header_done
);

  //internal logic
  logic [ 3:0] byte_counter;
  logic [15:0] src_port_reg;
  logic [15:0] dst_port_reg;
  logic [15:0] length_reg;
  logic [15:0] checksum_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || !parse_enable) begin
      byte_counter <= 4'd0;
    end else if (data_valid && ready_out && parse_enable) begin
      byte_counter <= byte_counter + 1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin : header_accumulation
    if (!rst_n) begin
      src_port_reg <= 16'd0;
      dst_port_reg <= 16'd0;
      length_reg   <= 16'd0;
      checksum_reg <= 16'd0;
    end else if (parse_enable && data_valid) begin
      case (byte_counter)
        4'd0: src_port_reg[15:8] <= data_in;
        4'd1: src_port_reg[7:0] <= data_in;
        4'd2: dst_port_reg[15:8] <= data_in;
        4'd3: dst_port_reg[7:0] <= data_in;
        4'd4: length_reg[15:8] <= data_in;
        4'd5: length_reg[7:0] <= data_in;
        4'd6: checksum_reg[15:8] <= data_in;
        4'd7: checksum_reg[7:0] <= data_in;
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin : output_latching
    if (!rst_n) begin
      src_port <= 16'd0;
      dst_port <= 16'd0;
      length   <= 16'd0;
      checksum <= 16'd0;
    end else if (latch_outputs) begin
      src_port <= src_port_reg;
      dst_port <= dst_port_reg;
      length   <= length_reg;
      checksum <= checksum_reg;
    end
  end

  assign header_done = (byte_counter == 4'd7) && parse_enable && data_valid && ready_out;


  assign port_match  = (dst_port == target_port);

endmodule
