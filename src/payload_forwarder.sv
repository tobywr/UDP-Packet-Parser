`timescale 1ns / 1ps
module payload_forwarder (
    input logic clk,
    input logic rst_n,

    //data stream
    input  logic [7:0] data_in,
    input  logic       data_valid_in,
    input  logic       packet_start,
    output logic       ready_out,

    //control
    input logic fwd_enable,
    input logic drop_enable,
    input logic header_done,

    //packet length
    input logic [15:0] udp_length,

    //output stream
    output logic [7:0] payload_data_out,
    output logic       payload_valid_out,
    output logic       payload_last,
    output logic       packet_done,
    input  logic       ready_in
);

  //register index of last payload byte when header completes.
  //payload bytes = length-8 and last has index length -9
  logic [15:0] last_index;
  logic length_valid;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last_index   <= 16'd0;
      length_valid <= 1'b0;
    end else if (header_done) begin
      last_index   <= udp_length - 16'd9;
      length_valid <= (udp_length > 16'd8);
    end
  end

  //byte counter (one incrament per payload byte in FWD or DROP)
  logic [15:0] payload_byte_counter;
  logic in_payload, s_beat, counter_enable, last_beat;

  assign in_payload = fwd_enable || drop_enable;
  assign s_beat = data_valid_in && ready_out;
  assign counter_enable = s_beat && in_payload;
  assign last_beat = length_valid && (payload_byte_counter == last_index);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) payload_byte_counter <= 16'd0;
    else if (!in_payload) payload_byte_counter <= 16'd0;
    else if (counter_enable) payload_byte_counter <= payload_byte_counter + 16'd1;
  end

  assign packet_done = counter_enable && last_beat;

  // skid buffer
  logic in_valid, in_ready, in_fire, in_last;
  assign in_valid = data_valid_in && fwd_enable && !packet_start;
  assign in_last  = last_beat;

  logic m_valid_r, skid_empty;
  logic [7:0] m_data_r, skid_data;
  logic m_last_r, skid_last;

  logic out_free;
  assign out_free = !m_valid_r || ready_in;
  assign in_ready = skid_empty;  // registered -> clean tready
  assign in_fire  = in_valid && in_ready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      m_valid_r  <= 1'b0;
      skid_empty <= 1'b1;
      m_data_r   <= 8'd0;
      m_last_r   <= 1'b0;
      skid_data  <= 8'd0;
      skid_last  <= 1'b0;
    end else begin
      if (out_free) begin
        if (!skid_empty) begin  // drain the skid first
          m_valid_r  <= 1'b1;
          m_data_r   <= skid_data;
          m_last_r   <= skid_last;
          skid_empty <= 1'b1;
        end else begin  // normal: input -> output register
          m_valid_r <= in_fire;
          m_data_r  <= data_in;
          m_last_r  <= in_last;
        end
      end else if (in_fire) begin  // output stalled
        skid_empty <= 1'b0;
        skid_data  <= data_in;
        skid_last  <= in_last;
      end
    end
  end

  assign payload_data_out  = m_data_r;
  assign payload_valid_out = m_valid_r;
  assign payload_last      = m_last_r;
  assign ready_out         = skid_empty;

endmodule
