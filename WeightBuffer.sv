`timescale 1 ps / 1 ps

module WeightBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface WB);
	genvar i;
	generate 
		for (i = 0; i < SIZE; i++) begin : VECTOR
			Vector #(WIDTH, ADDR) ROWS
					(.address_a		(WB.address.weight_buffer_input1[i]),
					.address_b		(WB.address.weight_buffer_input2[i]),
					.clock			(WB.clock),
					.data_a			(WB.data.weight_buffer_input1[i]),
					.data_b			(WB.data.weight_buffer_input2[i]),
					.rden_a			(WB.control.weight_buffer_read),
					.wren_a			(WB.control.weight_buffer_write1),
					.wren_b 			(WB.control.weight_buffer_write2),
					.q_a				(WB.data.weight_buffer_output[i]));
		end
	endgenerate 

endmodule : WeightBuffer