/* 
* FIFO Buffer Module
* Created By: Jordi Marcial Cruz
* Updated: March 4th, 2025
*
* Description:
* This module implements a FIFO buffer with configurable width and depth, supporting synchronous read 
* and write operations. It tracks occupancy with a counter, manages read/write pointers, and signals 
* full and empty states. Data is output on valid reads, and invalid operations result in high-impedance
*/

`timescale 1ps/1ps

module Fifo_Buffer 
  #(parameter WIDTH = 32,
   			   DEPTH = 8)
  (input logic 				clk,
   input logic 				reset_n,
   input logic 				read, 
   input logic 				write,
   input logic [WIDTH-1:0] 	data_in,
   
   output logic				empty,
   output logic 			full,
   output logic [WIDTH-1:0] data_out);

  localparam ADDR_WIDTH = $clog2(DEPTH);
  typedef enum logic {LOW, HIGH} signal_t;
  
  logic [WIDTH-1:0] queue [DEPTH-1:0];
  logic [DEPTH-1:0] cntr; 
  logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr; 
  
  assign full = (cntr == DEPTH) ? HIGH : LOW;
  assign empty = (cntr == 0) ? HIGH : LOW;
  
  logic valid_read;
  logic valid_write;
  
  assign valid_read = (read && !write && !empty);
  assign valid_write = (write && !read && !full);
  
  always_ff @(posedge clk or negedge reset_n) begin 
    if (!reset_n) begin 
      queue <= '{default : '0};
      cntr <= '0;
      wr_ptr <= '0;
      rd_ptr <= '0;
      data_out <= '0;
    end else if (valid_read) begin 
      cntr <= cntr - 1;
      data_out <= queue[rd_ptr];
      if (rd_ptr == DEPTH - 1)	rd_ptr <= 0;
      else 					   	rd_ptr <= rd_ptr + 1;
    end else if (valid_write) begin
      cntr <= cntr + 1;
      queue[wr_ptr] <= data_in;
      if (wr_ptr == DEPTH - 1) 	wr_ptr <= 0;
      else 					 	wr_ptr <= wr_ptr + 1;
    end else data_out <= 'z;
  end 
        
endmodule
