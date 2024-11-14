`timescale 1 ps / 1 ps

module InputBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface IB);
	genvar i;
	generate 
		for (i = 0; i < SIZE; i++) begin : VECTOR
			Vector #(WIDTH, ADDR) ROWS
					(.address_a		(IB.address.input_buffer_input1[i]),
					.address_b		(IB.address.input_buffer_input2[i]),
					.clock			(IB.clock),
					.data_a			(IB.data.input_buffer_input1[i]),
					.data_b			(IB.data.input_buffer_input2[i]),
					.rden_a			(IB.control.input_buffer_read),
					.wren_a			(IB.control.input_buffer_write1),
					.wren_b 			(IB.control.input_buffer_write2),
					.q_a				(IB.data.input_buffer_output[i]));
		end
	endgenerate 

endmodule : InputBuffer
