`timescale 1 ps / 1 ps

/* 
* Systolic Array Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 10, 2024
*
* Description:
* This module implements a Systolic Array of Processing Elements (PEs). 
* The array performs matrix multiplication in a parallel and pipelined manner.
*
* Inputs:
    * clock: Clock signal.
    * reset_n: Asynchronous reset signal (active low).
    * load: Load signal to enable loading of the PE accumulators.
    * clear: Clear signal to reset the PE accumulators.
    * carry_enable: Array of enable signals for carrying results between PEs.
    * weight_data: Array of weight values for each row of the array.
    * input_data: Array of input data values for each column of the array.
*
* Outputs:
    * output_data: Array of output results from each row of the array.
*/

module SystolicArray 
    #(parameter WIDTH = 8,  // Data width
                SIZE = 8) ( // Array dimensions (SIZE x SIZE)
	input logic clock, reset_n, load, clear, 
   input logic carry_enable [SIZE-1:0],
   input logic [WIDTH-1:0] weight_data [SIZE-1:0], 
   input logic [WIDTH-1:0] input_data [SIZE-1:0],
   output logic [WIDTH-1:0] output_data [SIZE-1:0]);
    
   // Internal signals for data propagation between PEs
   logic [WIDTH-1:0] weight_down [SIZE:0] [SIZE-1:0]; // Weight values passed down each column
   logic [WIDTH-1:0] data_in_across [SIZE-1:0] [SIZE:0]; // Input data passed across each row
   logic [WIDTH-1:0] result_across [SIZE-1:0] [SIZE:0]; // Results passed across each row
    
   genvar i,j;
   generate 
		for (i = 0; i < SIZE; i++) begin : PE_ROWS // Generate rows of PEs
			for (j = 0; j < SIZE; j++) begin : PE_COLUMNS // Generate columns of PEs
				// Instantiate a PE at each array position
            PE #(WIDTH) PE_inst 
					(.clock				(clock),
                     .reset_n          (reset_n),
                     .load             (load),
                     .clear            (clear),
                     .carry_enable     (carry_enable[j]),
                     .data_in          (data_in_across[i][j]),
                     .weight           (weight_down[i][j]),
                     .result_carry     (result_across[i][j]),
                     .result           (result_across[i][j+1]),
                     .weight_carry     (weight_down[i+1][j]),
                     .data_in_carry    (data_in_across[i][j+1]));                            
			end
    
             always_comb begin 
				weight_down[0][i] = weight_data[i]; // Assign weight data to the first row
                data_in_across[i][0] = input_data[i]; // Assign input data to the first column
                output_data[i] = result_across[i][SIZE]; // Assign the last result in the row to the output
			end
		end
	endgenerate 
    
endmodule : SystolicArray
