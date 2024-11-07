`timescale 1 ps / 1 ps

module SystolicArray 
	#(parameter WIDTH = 32,
					SIZE = 2)(
	input logic clock, reset_n, load, clear, 
	input logic carry_enable [SIZE-1:0],
	input logic [WIDTH-1:0] weight_data [SIZE-1:0], 
	input logic [WIDTH-1:0] input_data [SIZE-1:0],
	output logic [WIDTH-1:0] output_data [SIZE-1:0]);
	
	logic [WIDTH-1:0] weight_down [SIZE:0] [SIZE-1:0];
	logic [WIDTH-1:0] data_in_across [SIZE-1:0] [SIZE:0];
	logic [WIDTH-1:0] result_across [SIZE-1:0] [SIZE:0];
	
	genvar i,j;
	generate 
		for (i = 0; i < SIZE; i++) begin : PE_ROWS
			for (j = 0; j < SIZE; j++) begin : PE_COLUMNS
				PE #(WIDTH) PE_inst
								(.clock				(clock),
								.reset_n				(reset_n),
								.load					(load),
								.clear				(clear),
								.carry_enable		(carry_enable[j]),
								.data_in				(data_in_across[i][j]),
								.weight				(weight_down[i][j]),
								.result_carry		(result_across[i][j]),
								.result				(result_across[i][j+1]),
								.weight_carry		(weight_down[i+1][j]),
								.data_in_carry		(data_in_across[i][j+1]));							
			end
	
			always_comb begin 
				weight_down[0][i] = weight_data[i];
				data_in_across[i][0] = input_data[i];
				output_data[i] = result_across[i][SIZE];
			end
		end
	endgenerate 
	
endmodule : SystolicArray
