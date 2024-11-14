`timescale 1 ps / 1 ps

module InputBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface IB);
	genvar i;
	generate 
		for (i = 0; i < SIZE; i++) begin : VECTOR
			Vector #(WIDTH, ADDR) ROWS
					(.address_a		(IB.input_buffer_addr1[i]),
					.address_b		(IB.input_buffer_addr2[i]),
					.clock			(IB.clock),
					.data_a			(IB.input_buffer_data1[i]),
					.data_b			(IB.input_buffer_data2[i]),
					.rden_a			(IB.input_buffer_read),
					.wren_a			(IB.input_buffer_write1),
					.wren_b 			(IB.input_buffer_write2),
					.q_a				(IB.input_buffer_output_data[i]));
		end
	endgenerate 

endmodule : InputBuffer