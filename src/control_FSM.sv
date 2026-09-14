`timescale 1ns / 1ps
module control_FSM (
    input logic clk,
    input logic rst_n,

    input logic s_beat,
    input logic packet_start,

    input logic header_done,
    input logic port_match,
    input logic has_payload,
    input logic packet_done,

    output logic parse_enable,  // start capturing input bytes into header
    output logic fwd_enable,    //enable forwarding of payload bytes
    output logic drop_enable    //enable dropping of payload bytes
);

  typedef enum logic [1:0] {
    IDLE,             //waiting for new packet first byte
    PARSING_HEADER,   //recieving + parsing header
    FORWARD_PAYLOAD,  //forward payload bytes
    DROP_PAYLOAD      //dispose of payload silently
  } state_t;

  state_t current_state, next_state;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
  end


  always_comb begin
    //default
    next_state   = current_state;
    parse_enable = 1'b0;

    if (packet_start && s_beat) begin
      next_state   = PARSING_HEADER;
      parse_enable = 1'b1;
    end else begin

      case (current_state)
        IDLE: begin
          //packet start handled above.
        end

        PARSING_HEADER: begin
          parse_enable = 1'b1;
          if (header_done) begin
            if (!has_payload) next_state = IDLE;
            else if (port_match) next_state = FORWARD_PAYLOAD;
            else next_state = DROP_PAYLOAD;
          end
        end

        FORWARD_PAYLOAD, DROP_PAYLOAD: begin
          if (packet_done) next_state = IDLE;
        end

        default: next_state = IDLE;
      endcase
    end
  end


  //control signals for payload forwarder:
  assign fwd_enable  = (current_state == FORWARD_PAYLOAD);
  assign drop_enable = (current_state == DROP_PAYLOAD);

endmodule
