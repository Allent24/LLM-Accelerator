`timescale 1 ps / 1 ps

/* 
* Output Buffer Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 26, 2024
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
	
	logic fifo_read, vector_write;
	logic [ADDR-1:0] vector_addr;
	logic [SIZE-1:0] empty;
   logic [SIZE-1:0] full;
	
	DataController #(WIDTH, SIZE) Controller (
		.clock					(OB.clock), 
		.reset_n					(OB.reset_n),
		.array_data_ready		(OB.sa_data_ready),
		.empty					(empty),
		.full						(full),
		.read						(fifo_read), 
		.write					(vector_write),
		.transfer_ready		(OB.ob_ready_to_recv),
		.vector_addr			(vector_addr) );
	
	genvar j;
	generate 
		for (j = 0; j < SIZE; j++) begin : FIFO
	  // The FIFO instantiation if an output FIFO is required for data streaming
			  OB_FIFO #(WIDTH, SIZE) FIFO (
					.clock				(OB.clock), 
					.reset_n				(OB.reset_n), 
					.read					(read), 				// Secondary Controller 
					.write				(write), 			// Secondary Controller 
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
             .address_b      (),                   // Unused address port
             .clock          (OB.clock),           // Clock signal for synchronization
             .data_a         (vector_data_in[i]),     // Data input from systolic array
             .data_b         (),                   // Unused data port
             .rden_a         (),          			 // Read enable signal
             .wren_a         (),         				 // Write enable signal
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
	output logic read, write,
	output logic transfer_ready,
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
	
	assign read = (operation == TRANSFER) ? ON : OFF;
	assign write = (operation == LOAD) ? ON : OFF;
	assign transfer_ready = (operation == WAIT) ? ON : OFF;
	
endmodule : DataController






