`timescale 1 ps / 1 ps

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

endmodule 