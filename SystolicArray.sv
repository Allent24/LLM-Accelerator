`timescale 1 ps / 1 ps

/* 
* Systolic Array Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 14, 2024
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

module SystolicArray #(parameter WIDTH = 8, SIZE = 6) (DesignInterface SA);
	logic [WIDTH-1:0] weight_down [SIZE:0] [SIZE-1:0];
	logic [WIDTH-1:0] data_in_across [SIZE-1:0] [SIZE:0];
	logic [WIDTH-1:0] result_across [SIZE-1:0] [SIZE:0];
	
	genvar i,j;
	generate 
		for (i = 0; i < SIZE; i++) begin : PE_ROWS
			for (j = 0; j < SIZE; j++) begin : PE_COLUMNS
				PE #(WIDTH) PE_inst
								(.clock				(SA.clock),
								.reset_n				(SA.reset_n),
								.load					(SA.systolic_array_load),
								.clear				(SA.systolic_array_clear),
								.carry_enable		(SA.systolic_array_carry_enable[j]),
								.data_in				(data_in_across[i][j]),
								.weight				(weight_down[i][j]),
								.result_carry		(result_across[i][j]),
								.result				(result_across[i][j+1]),
								.weight_carry		(weight_down[i+1][j]),
								.data_in_carry		(data_in_across[i][j+1]));							
			end
	
			always_comb begin 
				weight_down[0][i] = SA.weight_buffer_output_data[i];
				data_in_across[i][0] = SA.input_buffer_output_data[i];
				SA.systolic_array_output_data[i] = result_across[i][SIZE];
			end
		end
	endgenerate 
	
endmodule : SystolicArray
