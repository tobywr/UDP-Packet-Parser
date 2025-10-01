`timescale 1ns / 1ps
module payload_forwarder (
    input logic clk,
    input logic rst_n,

    //data stream inputs
    input  logic [7:0] data_in,
    input  logic       data_valid_in,
    output logic       ready_out,

    //control commands
    input logic fwd_enable,
    input logic drop_enable,
    input logic header_done,

    //packet information
    input logic [15:0] udp_length,

    //processed data stream
    output logic [7:0] payload_data_out,   //output payload bytes
    output logic       payload_valid_out,  //if output byte is valid
    output logic       payload_last,       //LAST byte of payload
    input  logic       ready_in            //the next module is ready for data
);

  logic [15:0] payload_byte_counter;
  //calculate expected length of payload
  logic [15:0] expected_payload_length;
  assign expected_payload_length = udp_length - 16'd8;  //subtracting header size.

  logic payload_last_comb;
  assign payload_last_comb = (payload_byte_counter == expected_payload_length - 1) && payload_valid_out;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      payload_last <= 1'b0;
    end else begin
      payload_last <= payload_last_comb;
    end
  end

  logic counting_payload;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counting_payload <= 1'b0;
    end else if (header_done) begin
      counting_payload <= 1'b1;
    end else if (payload_last) begin
      counting_payload <= 1'b0;
    end
  end

  //generate 'last' signal.

  assign payload_data_out = data_in;  //data path always open (for simplicity)

  assign payload_valid_out = data_valid_in && fwd_enable;

  assign ready_out = ready_in || drop_enable;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || !counting_payload) begin
      payload_byte_counter <= 16'd0;
    end else if (data_valid_in && ready_out && fwd_enable) begin
      payload_byte_counter <= payload_byte_counter + 1;
    end else if (!fwd_enable && !drop_enable) begin
      payload_byte_counter <= 16'd0;
    end
  end
endmodule
