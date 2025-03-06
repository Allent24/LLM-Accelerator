/* 
* FIFO Buffer Assertions
* Created By: Jordi Marcial Cruz
* Updated: March 4th, 2025
*
* Description:
* This module defines SystemVerilog assertions to verify the correctness of a FIFO buffer's behavior. 
* It ensures that the FIFO correctly transitions to empty and full states, prevents invalid empty/full 
* flag conditions, and checks that read/write pointers do not match when the FIFO is neither empty nor full. 
*/

module Fifo_Assertions
    #(parameter WIDTH = 32,
   			   DEPTH = 8)(
	input logic 					clk,
   	input logic 					reset_n,
   	input logic 					read, 
   	input logic 					write,
   	input logic [WIDTH-1:0] 		data_in,
   
    // Internal Design Signals 
    input logic [DEPTH-1:0] cntr, 
   	input logic [$clog2(DEPTH)-1:0] wr_ptr, 
    input logic [$clog2(DEPTH)-1:0] rd_ptr, 
    input logic valid_read,
    input logic valid_write,
   
 	input logic						empty,
   	input logic 					full,
   	input logic [WIDTH-1:0]			data_out);
  
  `define assert_clk(arguments) \
  assert property (@(posedge clk) disable iff (!reset_n) arguments)
  
  ERROR_FIFO_DID_NOT_GO_EMPTY:
    `assert_clk((cntr == 1) && valid_read |-> ##1 empty);
      
  ERROR_FIFO_DID_NOT_GO_FULL:
    `assert_clk((cntr == DEPTH-1) && valid_write |-> ##1 full);
    
  ERROR_FIFO_SHOULD_NOT_BE_EMPTY:
    `assert_clk(cntr > 0 |-> !empty);
    
  ERROR_FIFO_SHOULD_NOT_BE_FULL:
    `assert_clk(cntr < DEPTH |-> !full);
    
  ERROR_FIFO_PTRS_ARE_MATCHING:
    `assert_clk((!empty && !full) |-> wr_ptr != rd_ptr);
    
endmodule : Fifo_Assertions
    
