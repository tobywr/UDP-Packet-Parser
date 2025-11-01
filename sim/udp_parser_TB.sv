`timescale 1ns / 1ps


module udp_parser_test;
  logic clk;
  logic rst_n;
  logic [15:0] target_port;
  logic [7:0] data_in;
  logic data_valid_in;
  logic ready_out;
  logic [7:0] payload_data_out;
  logic payload_valid_out;
  logic payload_last;
  logic ready_in;
  logic [15:0] src_port;
  logic [15:0] dst_port;
  logic [15:0] length;
  logic header_done;
  logic packet_start;

  //generate clock
  parameter CLK_PERIOD = 10;  //10ns = 100MHz
  always #(CLK_PERIOD / 2) clk = ~clk;


  //instantiate UDP_parser_top.sv
  udp_parser_top DUT (.*);

  //Defining packet as byte array : 

  byte unsigned packet[] = {
    //Header
    8'hC0,
    8'h00,  //Source port = 49152
    8'h04,
    8'hD2,  //Destination port = 1234
    8'h00,
    8'h11,  //Length : 17
    8'h00,
    8'h00,  //checksum always 0
    //Payload : TEST TEST
    8'h54,
    8'h45,
    8'h53,
    8'h54,
    8'h20,
    8'h54,
    8'h45,
    8'h53,
    8'h54
  };

  initial begin
    //Initialize everything to a value.
    clk = '0;
    rst_n = '0;
    target_port = 1234;  //Set target port to 1234
    data_in = '0;
    data_valid_in = '0;
    ready_in = 1;
    packet_start = 0;
    @(posedge clk);
    rst_n = '1;
    repeat(5) begin 
    @(posedge clk); //wait for logic to settle.
    end
    //driving data packet using a loop.
    $display("Driving data packet");
    packet_start = 1;
    @(posedge clk);
    data_valid_in = 1;
    data_in = packet[0];
    packet_start = 0;
    @(posedge clk);
    for (int i = 1; i < packet.size(); i++) begin
        data_in = packet[i];
        data_valid_in = 1;
        while(!ready_out) begin
            @(posedge clk);
        end
        @(posedge clk);
    end
    data_valid_in = 0;

    @(posedge clk);
    $display("");
    $display("Test finished");

    $display("Source Port = %0d", src_port);
    $display("Destination Port = %0d", dst_port);
    $display("Length = %0d", length);
    @(posedge clk);
    $display("Finished.");
    $finish;
  end

  always @(posedge clk) begin
    if (payload_valid_out) begin
      $write("%c", payload_data_out);
    end
  end
endmodule
