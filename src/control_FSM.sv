`timescale 1ns / 1ps
module control_FSM (
    input logic clk,
    input logic rst_n,

    input logic data_valid_in,
    input logic last_in,

    input logic header_done,

    input logic port_match,
    input logic checksum_ok,

    output logic parse_enable,  // start capturing input bytes into header
    output logic latch_outputs, //pulse to latch header outputs

    output logic fwd_enable,  //enable forwarding of payload bytes
    output logic drop_enable, //enable dropping of payload bytes

    output logic counter_rst,    //reset all counters
    output logic counter_enable  //incrament main packet byte counter

);

  typedef enum logic [2:0] {
    IDLE,             //waiting for new packet first byte
    PARSING_HEADER,   //recieving + parsing header
    LATCHING_HEADER,  //wait one cycle for header outputs to become valid
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
        if (data_valid_in) begin
          next_state = PARSING_HEADER;  //packet has started
        end
      end

      PARSING_HEADER: begin
        //check if we've got all 8-byte header
        if (header_done) begin
          next_state = LATCHING_HEADER;
        end
      end

      LATCHING_HEADER: begin
        next_state = CHECK_HEADER;
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
        if (last_in && data_valid_in) begin
          next_state = IDLE;
        end
      end

      DROP_PAYLOAD: begin
        next_state = DROP_PAYLOAD;
        if (last_in && data_valid_in) begin
          next_state = IDLE;
        end
      end
      default: next_state = IDLE;
    endcase
  end

  //control signals for Header Parser:
  assign parse_enable = (current_state == IDLE) || (data_valid_in == 1'd1);
  assign latch_outputs = (current_state == LATCHING_HEADER);

  //control signals for payload forwarder:
  assign fwd_enable = (current_state == FORWARD_PAYLOAD) || (current_state == CHECK_HEADER && checksum_ok && port_match);
  assign drop_enable = (current_state == DROP_PAYLOAD);

  //control signals for counters:
  assign counter_rst = (current_state == IDLE);  //reset counter when idle
  //enable counter when processing data in any state
  assign counter_enable = ((current_state == PARSING_HEADER) ||
                          (current_state == FORWARD_PAYLOAD) ||
                          (current_state == DROP_PAYLOAD)) && data_valid_in;
endmodule
