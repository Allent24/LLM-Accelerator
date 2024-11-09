// /***
`timescale 1 ps / 1 ps
module SystolicArray_TB
	#(parameter WIDTH = 32,	// Output for SA must be 22 bits or greater for a 8-bit 64x64 matrix
					SIZE = 2);
	logic clock, reset_n, load, clear; 
	logic carry_enable [SIZE-1:0];
	logic [WIDTH-1:0] weight_data [SIZE-1:0]; 
	logic [WIDTH-1:0] input_data [SIZE-1:0];
	logic [WIDTH-1:0] output_data [SIZE-1:0];
	
	SystolicArray #(WIDTH, SIZE) DUT (.*);
	
	logic [WIDTH-1:0] partialSum [SIZE-1:0] [SIZE-1:0];
	logic [WIDTH-1:0] storedResults [SIZE-1:0][$];
	int errors = 0;

	initial begin 
		clock = 1;
		forever #5 clock = ~clock;
	end
	
	task resetDUT();
		reset_n = 0;
		load = 0;
		clear = 0;
		partialSum = '{default: '0};
		carry_enable = '{default: '0};
		weight_data = '{default: '0};
		input_data = '{default: '0};
		#5;
		reset_n = 1;
	endtask
	
	task inputData (input logic [WIDTH-1:0] w0, w1, x0, x1);
		weight_data[0] <= w0;
		input_data[0] <= x0;
		weight_data[1] <= w1;
		input_data[1] <= x1;
		
		partialSum[0][0] <= partialSum[0][0] + (x0 * w0);
		partialSum[0][1] <= partialSum[0][1] + (x0 * w1);
		partialSum[1][0] <= partialSum[1][0] + (x1 * w0);
		partialSum[1][1] <= partialSum[1][1] + (x1 * w1);
		@(posedge clock);
	endtask 
	
	task carryResults();
		for (int col = SIZE - 1; col > -1; col--) begin
			for (int row = 0; row < SIZE; row++) begin 
				storedResults[row].push_back(output_data[row]);
			end
			$display("Row Data for Clock Edge %0d", SIZE-1-col);
			showRowData();
			carry_enable[col] <= 1;
			@(posedge clock);
		end
	endtask
	
	task clearArray();
		//	
	endtask
	
	function void checkResults();
		int returnedResult;
		for (int row = 0; row < SIZE; row++) begin
			for (int col = SIZE - 1; col > -1; col--) begin 
				returnedResult = storedResults[row].pop_front();
				assert (returnedResult == partialSum[row][col])
				else begin $error("Expected PE[%0d][%0d] result: %0d does not match result: %0d",
										row,col,partialSum[row][col], returnedResult);errors++; end
			end
		end
	endfunction
	
	function void showRowData();
		for (int row = 0; row < SIZE; row++) begin 
			$display("Output Data Row %0d: %0d",row, output_data[row]);
		end
		$display("***********************************************");
	endfunction
	
	initial begin 
		$display("***********************************************");
		$display("Beginning Testbench, resetting dut...");
		$display("***********************************************");
		resetDUT();

		@(posedge clock);
		repeat (10) begin 
			inputData($urandom_range(1,255),$urandom_range(1,255),
						 $urandom_range(1,255),$urandom_range(1,255));
		end
		load <= 1;
		@(posedge clock);
		carryResults();
		
		repeat (10) begin 
			@(posedge clock);
		end
		
		checkResults();
		
		$display("***********************************************");
		if (errors != 0) $display("Testbench failed with %0d errors!",errors);
		else $display("Testbench passed!",);
		$display("***********************************************");
		$finish;
	end 
	
endmodule : SystolicArray_TB
// ***/
