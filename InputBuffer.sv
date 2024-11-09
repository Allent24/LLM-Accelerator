module InputBuffer 
	#(parameter WIDTH = 8,
					SIZE = 2,
					ADDR = $clog2(SIZE))
	(input logic clock,
	input logic rd1, wr1, wr2,
	input logic [WIDTH-1:0] data1 [SIZE-1:0],
	input logic [WIDTH-1:0] data2 [SIZE-1:0],
	input logic [ADDR-1:0] addr1 [SIZE-1:0],
	input logic [ADDR-1:0] addr2 [SIZE-1:0],
	output logic [WIDTH-1:0] elementData [SIZE-1:0]);
	
	genvar i;
	generate 
		for (i = 0; i < SIZE; i++) begin : Inst_Vectors
			MatrixVectorRAM #(WIDTH, ADDR) Vectors
					(.address_a(addr1[i]),
					.address_b(addr2[i]),
					.clock(clock),
					.data_a(data1[i]),
					.data_b(data2[i]),
					.q_a(elementData[i]),
					.rden_a(rd1),
					.wren_a(wr1),
					.wren_b(wr2));
		end
	endgenerate 

endmodule : InputBuffer