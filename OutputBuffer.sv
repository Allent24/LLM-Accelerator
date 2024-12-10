`timescale 1 ps / 1 ps

/* 
* Output Buffer Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: December 10, 2024
*
* Description:
* This module implements an output buffer to store results from the LLM Accelerator and facilitate their transfer to other components. 
* The buffer can store multiple vectors and is parameterizable in terms of data width and size, allowing it to accommodate different
* processing requirements.
*
* Inputs:
*   - ob_addr_in1: Address lines to specify which part of the output buffer to read or write.
*   - clock: Clock signal for synchronous operations.
*   - reset_n: Active low reset signal to reset the buffer.
*   - sa_data_out: Data input from the systolic array output.
*   - ob_rd: Read enable signal to allow reading from the output buffer.
*   - ob_wr1: Write enable signal for storing data from the systolic array into the buffer.
*
* Outputs:
*   - ob_data_out: Data output from the output buffer for external usage.
*/

module OutputBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface.OutputBuffer OB); 
	logic [WIDTH-1:0] array_data_out [SIZE-1:0];
	logic [WIDTH-1:0] fifo_data_out [SIZE-1:0];
	logic [WIDTH-1:0] vector_data_in [SIZE-1:0];
	
	// Sequential logic for pipelining array output data (Stage 1) 
	always_ff @(posedge OB.clock or negedge OB.reset_n) begin 
		if (!OB.reset_n) array_data_out <= '{default: '0};
      else array_data_out <= OB.sa_data_out;
   end
	
	logic fifo_read, fifo_write;
	logic vector_read, vector_write;
	logic [ADDR-1:0] vector_addr;
	logic [SIZE-1:0] empty;
   logic [SIZE-1:0] full;
	
	DataController #(WIDTH, SIZE) Controller (
		.clock					(OB.clock), 
		.reset_n					(OB.reset_n),
		.array_data_ready		(OB.sa_data_ready),
		.empty					(empty),
		.full						(full),
		.fifo_read				(fifo_read), 
		.fifo_write				(fifo_write),
		.ready_to_rcv			(OB.ob_ready_to_recv),
		.vector_read			(vector_read),
		.vector_write 			(vector_write),
		.vector_addr			(vector_addr) );
	
	genvar j;
	generate 
		for (j = 0; j < SIZE; j++) begin : FIFO
	  // The FIFO instantiation if an output FIFO is required for data streaming
			  OB_FIFO #(WIDTH, SIZE) FIFO (
					.clock				(OB.clock), 
					.reset_n				(OB.reset_n), 
					.read					(fifo_read), 				// Secondary Controller 
					.write				(fifo_write), 			// Secondary Controller 
					.data_in				(array_data_out[j]),
					.empty				(empty[j]),
					.full					(full[j]),
					.data_out			(fifo_data_out[j]));
		 end
	endgenerate 
	
	// Sequential logic for pipelining FIFO output data (Stage 2)
	always_ff @(posedge OB.clock or negedge OB.reset_n) begin 
		if (!OB.reset_n) vector_data_in <= '{default: '0};
      else vector_data_in <= fifo_data_out;
   end

	genvar i;
   generate 
		for (i = 0; i < SIZE; i++) begin : VECTOR
             // Instantiate Vector module for each vector element in the output buffer
			Vector #(WIDTH, ADDR) ROWS
				(.address_a      (vector_addr),   			// Address input for read/write access
             .address_b      (),                   	// Unused address port
             .clock          (OB.clock),           	// Clock signal for synchronization
             .data_a         (vector_data_in[i]),     // Data input from systolic array
             .data_b         (),                  		 // Unused data port
             .rden_a         (vector_read),          	// Read enable signal
             .wren_a         (vector_write),         	 // Write enable signal
             .wren_b         (),                   // Unused write enable port
             .q_a            (OB.ob_data_out[i])); // Output data from the buffer
         end
     endgenerate 
		
endmodule : OutputBuffer

module DataController #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (
	input logic clock, reset_n,
	input logic array_data_ready,
	input logic [SIZE-1:0] empty,
   input logic [SIZE-1:0] full,
	output logic fifo_read, fifo_write,
	output logic ready_to_rcv,
	output logic vector_read, vector_write,
	output logic [ADDR-1:0] vector_addr);
	
	logic fifo_full, fifo_empty;
	assign fifo_full = &full;
	assign fifo_empty = &empty;
	
	enum logic {OFF, ON} switch_t;
	typedef enum logic [1:0] {WAIT, TRANSFER, LOAD} operation_t;
	operation_t operation;
	
	always_ff @(posedge clock or negedge reset_n) begin 
		if (!reset_n) begin
			operation <= WAIT;
		end else begin 
			case(operation) 
			WAIT:			operation <= (fifo_empty && array_data_ready) ? TRANSFER : WAIT;
			TRANSFER:	operation <= (fifo_full) ? LOAD : TRANSFER;
			LOAD: 		operation <= (fifo_empty) ? WAIT : LOAD;
			endcase
		end 
	end 
	
	always_ff @(posedge clock or negedge reset_n) begin 
		if (!reset_n) vector_addr <= 0;
		else if (LOAD) vector_addr <= vector_addr + 1;
		else vector_addr <= 0;
	end
	
	assign ready_to_rcv = (operation == WAIT) ? ON : OFF;
	assign fifo_write = (operation == TRANSFER) ? ON : OFF;
	assign fifo_read = (operation == LOAD) ? ON : OFF;
	assign vector_write = (operation == LOAD) ? ON : OFF;
	
endmodule : DataController

module OB_FIFO #(parameter WIDTH = 8, SIZE = 6)(
	input logic clock, reset_n, read, write,
	input logic [WIDTH-1:0] data_in,
	output logic empty, full,
	output logic [WIDTH-1:0] data_out);
	
	localparam ADDR_SIZE = $clog2(SIZE);
	enum logic {OFF, ON} switch_t;
	
	logic valid_read, valid_write;
	logic [ADDR_SIZE-1:0] counter, rd_ptr, wr_ptr;
	logic [WIDTH-1:0] memory [SIZE-1:0];
	
	assign valid_read = (!empty && !write && read) ? ON : OFF;
	assign valid_write = (!full && !read && write) ? ON : OFF;
	
	assign full = (counter == SIZE) ? ON : OFF;
	assign empty = (counter == 0) ? ON : OFF;
	
	always_ff @(posedge clock or negedge reset_n) begin
		if (!reset_n) begin 
			memory <= '{default : '0};
			counter <= '0;
			wr_ptr <= '0;
			rd_ptr <= '0;
		end else if (valid_write) begin
			memory[wr_ptr] <= data_in;
			counter <= counter + 1;	
			if (wr_ptr == SIZE - 1) wr_ptr <= 0;
			else wr_ptr <= wr_ptr + 1;
		end else if (valid_read) begin 
			counter <= counter - 1;
			if (rd_ptr == SIZE - 1) rd_ptr <= 0;
			else rd_ptr <= rd_ptr + 1;
		end 
	end
	
	assign data_out = memory[rd_ptr];

endmodule : OB_FIFO




