`timescale 1 ps / 1 ps

/* 
* Input Buffer Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 26, 2024
*
* Description:
* This module implements an input buffer for storing data inputs to the LLM Accelerator. 
* The buffer takes input from multiple sources, stores the data in a vector, and makes it available to downstream processing elements. 
* It is parameterizable in terms of data width and size, making it flexible to accommodate different system requirements.
*
* 		
*/

module ControlUnit #(parameter SIZE = 2) (DesignInterface.Controller CU); 
	logic stop_pass;
	logic stop_read_ib; 
	logic stop_read_wb; 
	// logic stop_write_ib;
	// logic stop_write_wb;
	
	assign stop_read_ib = (CU.ib_addr_in1 == SIZE) ? 1 : 0;
	assign stop_read_wb = (CU.wb_addr_in1 == SIZE) ? 1 : 0;
	// assign stop_write_ib = ((CU.ib_addr_in1 == SIZE) && (CU.ib_addr_in2 == SIZE)) ? 1 : 0;
	// assign stop_write_ib = ((CU.wb_addr_in1 == SIZE) && (CU.wb_addr_in2 == SIZE)) ? 1 : 0;
	
	typedef enum logic [1:0] {READ, PASS, CLEAR, WRITE} states_t;
	
	states_t state, next_state;
	
	always_ff @ (posedge CU.clock or negedge CU.reset_n) begin
		if (!CU.reset_n)
			state <= CLEAR;
		else 
			state <= next_state;
	end

	always_ff @ (posedge CU.clock or negedge CU.reset_n) begin
		if (!CU.reset_n) begin
			CU.ib_addr_in1 <= 0;
			CU.wb_addr_in1 <= 0;
		end
		else if (state == READ) begin
			CU.ib_addr_in1 <= CU.ib_addr_in1 + 1;
			CU.wb_addr_in1 <= CU.wb_addr_in1 + 1;
		end else begin 
			CU.ib_addr_in1 <= 0;
			CU.wb_addr_in1 <= 0;
		end
	end
	
	always_comb begin
		case (state) 
			READ: next_state = (stop_read_ib && stop_read_wb) ? PASS : READ;
			PASS: next_state = (stop_pass == SIZE) ? CLEAR : PASS;
			CLEAR: next_state = WRITE;
			WRITE: next_state = READ;
		endcase
	end
	
	always_comb begin
	
		CU.ib_rd1 = 0; 
		CU.ib_wr1 = 0; 
		CU.ib_wr2 = 0; 
		// CU.ib_addr_in1 = CU.ib_addr_in1 + 1; // idk
		CU.ib_addr_in2 = 0; // Doesn't matter
		
		CU.wb_rd1 = 0;
		CU.wb_wr1 = 0;
		CU.wb_wr2 = 0; 
		// CU.wb_addr_in1 = CU.wb_addr_in1 + 1;
		CU.wb_addr_in2 = 0; // Doesn't matter
		
		CU.sa_load = 0;
		CU.sa_clear = 0;
		CU.sa_carry_en = '{default: '0};
		CU.sa_data_ready = 0;
		
		case (state) 
			READ: begin
				CU.ib_rd1 = 1; 
				CU.ib_wr1 = 0; 
				CU.ib_wr2 = 0; 
				// CU.ib_addr_in1 = CU.ib_addr_in1 + 1; // idk
				CU.ib_addr_in2 = 0; // Doesn't matter
				
				CU.wb_rd1 = 1;
				CU.wb_wr1 = 0;
				CU.wb_wr2 = 0; 
				// CU.wb_addr_in1 = CU.wb_addr_in1 + 1;
				CU.wb_addr_in2 = 0; // Doesn't matter
				
				CU.sa_load = 0;
				CU.sa_clear = 0;
				CU.sa_carry_en = '{default: '0};
				CU.sa_data_ready = 0;
			end
			
			PASS: begin
				CU.ib_rd1 = 0; 
				CU.ib_wr1 = 0; 
				CU.ib_wr2 = 0; 
				CU.ib_addr_in2 = 0; 
				
				CU.wb_rd1 = 0;
				CU.wb_wr1 = 0;
				CU.wb_wr2 = 0; 
				CU.wb_addr_in2 = 0; // Doesn't matter
				
				CU.sa_load = 1;
				CU.sa_clear = 0;
				CU.sa_carry_en = '{default: '1};
				CU.sa_data_ready = 1;
			end
			
			CLEAR: begin
				CU.ib_rd1 = 0; 
				CU.ib_wr1 = 0; 
				CU.ib_wr2 = 0; 
				CU.ib_addr_in2 = 0; 
				
				CU.wb_rd1 = 0;
				CU.wb_wr1 = 0;
				CU.wb_wr2 = 0; 
				CU.wb_addr_in2 = 0; // Doesn't matter
				
				CU.sa_load = 0;
				CU.sa_clear = 1;
				CU.sa_carry_en = '{default: '0};
				CU.sa_data_ready = 0;
			end
			
			WRITE: begin
				CU.ib_rd1 = 0; 
				CU.ib_wr1 = 1; 
				CU.ib_wr2 = 1; 
				// CU.ib_addr_in1 = CU.ib_addr_in1 + 1; // idk
				// CU.ib_addr_in2 = CU.ib_addr_in2 + 1; 
				
				CU.wb_rd1 = 0;
				CU.wb_wr1 = 1;
				CU.wb_wr2 = 1; 
				// CU.wb_addr_in1 = CU.wb_addr_in1 + 1; 
				// CU.wb_addr_in2 = CU.wb_addr_in2 + 1; 
				
				CU.sa_load = 0;
				CU.sa_clear = 0;
				CU.sa_carry_en = '{default: '0};
				CU.sa_data_ready = 0;
			end

		endcase
	end
endmodule : ControlUnit
