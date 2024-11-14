`timescale 1 ps / 1 ps

module WeightBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface WB);
	genvar i;
	generate 
		for (i = 0; i < SIZE; i++) begin : VECTOR
			Vector #(WIDTH, ADDR) ROWS
					(.address_a		(WB.data_path.weight_buffer_addr1[i]),
					.address_b		(WB.data_path.weight_buffer_addr2[i]),
					.clock			(WB.clock),
					.data_a			(WB.data_path.weight_buffer_data1[i]),
					.data_b			(WB.data_path.weight_buffer_data2[i]),
					.rden_a			(WB.control.weight_buffer_read),
					.wren_a			(WB.control.weight_buffer_write1),
					.wren_b 			(WB.control.weight_buffer_write2),
					.q_a				(WB.data_path.weight_buffer_output_data[i]));
		end
	endgenerate 

endmodule : WeightBuffer