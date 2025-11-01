`timescale 1ns / 1ps
module control_FSM (
    input logic clk,
    input logic rst_n,

    input logic data_valid_in,
    input logic packet_last,
    input logic packet_start,

    input logic header_done,
    input logic port_match,
    input logic checksum_ok,

    output logic parse_enable,  // start capturing input bytes into header

    output logic fwd_enable,  //enable forwarding of payload bytes
    output logic drop_enable, //enable dropping of payload bytes

    output logic counter_rst,    //reset all counters
    output logic counter_enable  //incrament main packet byte counter

);

  typedef enum logic [2:0] {
    IDLE,             //waiting for new packet first byte
    PARSING_HEADER,   //recieving + parsing header
    CHECK_HEADER,     //header is done, check if OK (checksum, port match)
    FORWARD_PAYLOAD,  //forward payload bytes
    DROP_PAYLOAD      //dispose of payload silently
  } state_t;

  state_t current_state, next_state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;  //update state every clock edge
    end
  end


  always_comb begin
    //default
    next_state = current_state;

    case (current_state)
      IDLE: begin
        if (packet_start) begin
          next_state = PARSING_HEADER;  //packet has started
          parse_enable = 1'b1;
        end
      end

      PARSING_HEADER: begin
        //check if we've got all 8-byte header
        parse_enable = 1'b1;
        if (header_done) begin
          next_state = CHECK_HEADER;
        end
      end

      CHECK_HEADER: begin
        // check if port is correct + checksum
        if (checksum_ok && port_match) begin
          next_state = FORWARD_PAYLOAD;
        end else begin
          next_state = DROP_PAYLOAD;  //drop if either check fails. (ports wrong or data is corrupt)
        end
      end

      FORWARD_PAYLOAD: begin
        next_state = FORWARD_PAYLOAD;
        if (packet_last && data_valid_in) begin
          next_state = IDLE;
        end
      end

      DROP_PAYLOAD: begin
        next_state = DROP_PAYLOAD;
        if (packet_last && data_valid_in) begin
          next_state = IDLE;
        end
      end
      default: next_state = IDLE;
    endcase
  end


  //control signals for payload forwarder:
  assign fwd_enable = (next_state == FORWARD_PAYLOAD);
  assign drop_enable = (current_state == DROP_PAYLOAD);

  //control signals for counters:
  assign counter_rst = (current_state == IDLE);  //reset counter when idle
  //enable counter when processing data in any state
  assign counter_enable = (data_valid_in && current_state != IDLE);
endmodule
