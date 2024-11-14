/* 
* Design Interface for Input/Weight/Output Buffers, Controller, and Systolic Array
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator
* Updated: November 14, 2024
*
* Description:
* This interface defines the signals used for controlling and managing the Input/Weight/Output Buffers, Controller, and 
* the Systolic Array in a matrix multiplication accelerator design. It provides the necessary signals 
* for reading, writing, and controlling the input data and addresses for efficient processing by the 
* Systolic Array.
*/

interface DesignInterface #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (input logic clock);
	// Shared Signals 
	logic reset_n;
	
	// Input Buffer Control, Data, and Address Signals 
	logic input_buffer_read; 
	logic input_buffer_write1;
	logic input_buffer_write2;
	logic [WIDTH-1:0] input_buffer_data1 [SIZE-1:0];
	logic [WIDTH-1:0] input_buffer_data2 [SIZE-1:0];
	logic [ADDR-1:0] input_buffer_addr1 [SIZE-1:0];
	logic [ADDR-1:0] input_buffer_addr2 [SIZE-1:0];
	logic [WIDTH-1:0] input_buffer_output_data [SIZE-1:0];
	
	// Weight Buffer Control, Data, and Address Signals 
	logic weight_buffer_read; 
	logic weight_buffer_write1;
	logic weight_buffer_write2;
	logic [WIDTH-1:0] weight_buffer_data1 [SIZE-1:0];
	logic [WIDTH-1:0] weight_buffer_data2 [SIZE-1:0];
	logic [ADDR-1:0] weight_buffer_addr1 [SIZE-1:0];
	logic [ADDR-1:0] weight_buffer_addr2 [SIZE-1:0];
	logic [WIDTH-1:0] weight_buffer_output_data [SIZE-1:0];
	
	// Systolic Array Control and Data Signals 
	logic systolic_array_load;
   logic systolic_array_clear;
	logic systolic_array_carry_enable [SIZE-1:0];
	logic [WIDTH-1:0] systolic_array_output_data [SIZE-1:0];

	
endinterface : DesignInterface
