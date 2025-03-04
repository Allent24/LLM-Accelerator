`timescale 1 ps / 1 ps

/* 
* Processing Element (PE) Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 10, 2024
*
* Description:
* This module implements a single Processing Element (PE) for a Systolic Array. 
* Each PE performs a multiply-accumulate operation on input data and weights.
* This module utilizes Logic Element (LE) multipliers instead of Digital Signal Processing (DSP) blocks
* to achieve a higher maximum operating frequency.
*
* Inputs:
    * clock: Clock signal.
    * reset_n: Asynchronous reset signal (active low).
    * load: Load signal to enable loading of the accumulator.
    * clear: Clear signal to reset the accumulator.
    * carry_enable: Enable signal for carrying results between PEs.
    * data_in: Input data.
    * weight: Weight value.
    * result_carry: Carry result from the previous PE.
*
* Outputs:
    * result: Output result of the PE.
    * weight_carry: Carry output for the weight (to the next PE in the row).
    * data_in_carry: Carry output for the input data (to the next PE in the column). 
*/

module PE 
	#(parameter WIDTH = 8)(
	input logic clock, reset_n, load, clear, carry_enable,
	input logic [WIDTH-1:0] data_in, weight, result_carry,
	output logic [WIDTH-1:0] result, weight_carry, data_in_carry);
	
	logic [WIDTH-1:0] mult_result, accumulator;
	
 mult_gen_2 Multiplier
    (.A(data_in),
    .B(weight),
    .P(mult_result));

	always_ff @(posedge clock or negedge reset_n) begin 
		if (!reset_n) 					accumulator <= '0;
		else if (!load && !clear) 	accumulator <= accumulator + mult_result[WIDTH-1:0];
		else if (load && !clear) 	accumulator <= accumulator;
		else if (clear)  			   accumulator <= '0;
	end
	
	assign result = (carry_enable) ? result_carry : accumulator;
	assign weight_carry = weight;
	assign data_in_carry = data_in;

endmodule : PE