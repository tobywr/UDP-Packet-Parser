`timescale 1ns / 1ps
module cycle_counter (
    input logic clk,
    input logic rst_n,

    input logic start_counter,
    input logic stop_counter,

    output logic [15:0] cycle_count,
    output logic is_counting
);
  logic [15:0] current_count_reg;
  logic        is_counting_reg;
  assign is_counting = is_counting_reg;
  //is counting logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      is_counting_reg <= 1'b0;
    end else if (start_counter) begin
      is_counting_reg <= 1'b1;
    end else if (stop_counter) begin
      is_counting_reg <= 1'b0;
    end
  end
  //counting logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_count_reg <= 16'd0;
    end else if (start_counter) begin
      current_count_reg <= 16'd1;  //start from 1
    end else if (is_counting_reg) begin
      current_count_reg <= current_count_reg + 1;
    end
  end
  //latch counter_reg to cycle_count when stop_counter asserted
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_count <= 16'd0;
    end else if (stop_counter) begin
      cycle_count <= current_count_reg;
    end
  end

endmodule
