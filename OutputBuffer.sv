`timescale 1 ps / 1 ps

module OutputBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface OB);
	genvar i;
	generate 
		for (i = 0; i < SIZE; i++) begin : VECTOR
			Vector #(WIDTH, ADDR) ROWS
					(.address_a		(OB.address.output_buffer_input1[i]),
					.address_b		(OB.address.output_buffer_input2[i]),
					.clock			(OB.clock),
					.data_a			(OB.data.systolic_array_output[i]),
					.data_b			(),
					.rden_a			(OB.control.output_buffer_read),
					.wren_a			(OB.control.output_buffer_write),
					.wren_b 			(),
					.q_a				(OB.data.output_buffer_output[i]));
		end
	endgenerate 

endmodule 
