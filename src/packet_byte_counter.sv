module packet_byte_counter (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        counter_rst,
    input  logic        counter_enable,
    input  logic [15:0] udp_length,
    output logic        packet_last
);

  // internal registers
  logic [15:0] udp_length_reg;
  logic [15:0] target_count;        // udp_length - 1
  logic [15:0] byte_count;
  logic        packet_last_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || counter_rst) begin
      udp_length_reg <= 16'd0;
      target_count   <= 16'd0;
    end else if (counter_enable) begin
      udp_length_reg <= udp_length;
      target_count   <= udp_length - 16'd1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || counter_rst) begin
      byte_count <= 16'd0;
    end else if (counter_enable) begin
      if (byte_count < target_count)
        byte_count <= byte_count + 1;
      // else hold
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || counter_rst) begin
      packet_last_reg <= 1'b0;
    end else if (counter_enable) begin
      packet_last_reg <= (byte_count == target_count);
    end
  end

  assign packet_last = packet_last_reg;

endmodule