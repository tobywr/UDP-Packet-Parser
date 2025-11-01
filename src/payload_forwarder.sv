`timescale 1ns / 1ps
module payload_forwarder (
    input  logic        clk,
    input  logic        rst_n,

    // Data stream
    input  logic [7:0]  data_in,
    input  logic        data_valid_in,
    output logic        ready_out,

    // Control
    input  logic        fwd_enable,
    input  logic        drop_enable,
    input  logic        header_done,

    // Packet info
    input  logic [15:0] udp_length,

    // Output stream
    output logic [7:0]  payload_data_out,
    output logic        payload_valid_out,
    output logic        payload_last,
    input  logic        ready_in
);

  // === 1. Register expected length and compute target = max(udp_length-8, 0) ===
  logic [15:0] expected_payload_length_reg;
  logic [15:0] target_count;
  logic        length_valid;  // high when length is loaded

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      expected_payload_length_reg <= 16'd0;
      target_count               <= 16'd0;
      length_valid               <= 1'b0;
    end else if (header_done) begin
      expected_payload_length_reg <= udp_length;
      if (udp_length > 16'd8) begin
        target_count <= udp_length - 16'd8;
        length_valid <= 1'b1;
      end else begin
        target_count <= 16'd0;
        length_valid <= 1'b0;
      end
    end else if (!fwd_enable) begin
      length_valid <= 1'b0;  // clear when not forwarding
    end
  end

  // === 2. Payload byte counter ===
  logic [15:0] payload_byte_counter;
  logic [15:0] payload_byte_counter_next;
  logic        counter_enable;

  assign counter_enable = data_valid_in && ready_out && fwd_enable;

  always_comb begin
    if (length_valid && payload_byte_counter < target_count)
      payload_byte_counter_next = payload_byte_counter + 1;
    else
      payload_byte_counter_next = payload_byte_counter;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      payload_byte_counter <= 16'd0;
    else if (!fwd_enable)
      payload_byte_counter <= 16'd0;
    else if (counter_enable)
      payload_byte_counter <= payload_byte_counter_next;
  end

  // === 3. Register payload_last ===
  logic payload_last_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      payload_last_reg <= 1'b0;
    else if (!fwd_enable)
      payload_last_reg <= 1'b0;
    else if (counter_enable)
      payload_last_reg <= length_valid && (payload_byte_counter == target_count);
  end

  // === Output assignments ===
  assign payload_data_out   = data_in;
  assign payload_valid_out  = data_valid_in && fwd_enable && ready_in;
  assign ready_out          = drop_enable || (fwd_enable ? ready_in : 1'b1);
  assign payload_last       = payload_last_reg;

endmodule