`timescale 1 ps / 1 ps

/* 
* Processing Element (PE) Testbench
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 9, 2024
*
* Description:
* This testbench verifies the functionality of the PE module. 
* It provides stimuli to the PE and checks the output against expected results.
* The testbench includes tasks for reset, multiplication, accumulation, 
* carry handling, and clearing values.
*/

module PE_TB
	#(parameter WIDTH = 16);
	logic clock, reset_n, load, clear, carry_enable;
	logic [WIDTH-1:0] data_in, weight, result_carry;
	logic [WIDTH-1:0] result, weight_carry, data_in_carry;
	
	// Instantiate the Device Under Test (DUT)
	PE #(WIDTH) DUT (.*);
	
	// Internal testbench signals
	logic [WIDTH-1:0] partialSum, expectedResult;
	int errors = 0;
	typedef enum int {INPUTS, MULTIPLICATION, RESULT, ACCUMULATOR, ALL} display_t;
	
	initial begin 
		clock = 1;
		forever #5 clock = ~clock;
	end
	
	// Task to reset the DUT
	task resetDUT();
		reset_n = 0;
		load = 0;
		clear = 0;
		carry_enable = 0;
		data_in = '0;
		weight = '0;
		result_carry = '0;
		partialSum = '0;
		expectedResult = '0;
		#5; reset_n = 1; showValueFor(ALL);
	endtask
	
	// Task to perform multiplication
	task multiply (input logic [WIDTH-1:0] x, w);
		data_in <= x;
		weight <= w;
		partialSum <= partialSum + (x * w);
		@(posedge clock);
		// showValueFor(INPUTS); // Optionally display input values
	endtask 
	
	// Task to perform accumulation
	task accumulate (input int numOfMults, input logic [WIDTH-1:0] inputData, weightData);
		int i;
		load <= 0;
		for (i = 0; i < numOfMults; i ++) begin
			multiply(inputData,weightData); // Perform multiple multiplications
		end
		
		showValueFor(MULTIPLICATION); // Display multiplication information
		load <= 1;
		@(posedge clock);
		expectedResult <= expectedResult + partialSum; // Calculate expected result
		@(posedge clock);
		
		partialSum <= '0;
		showValueFor(RESULT); // Display result information
		assert (result == expectedResult) // Check result against expected value
		else begin $error("Result: %0d does not match Expected Result: %0d\n",
					         result, expectedResult); errors++; end
		@(posedge clock);
	endtask 
	
	// Task to test carry functionality
	task setCarry();
		result_carry <= $urandom_range(1, 1000); // Generate random carry value
		carry_enable <= 1;
		@(posedge clock);
		assert(result == result_carry) // Check if carry value is passed through correctly
		else begin $error("Expected result carry %0d to pass through, received %0d!",
								result_carry, result); errors++; end
		carry_enable <= 0;
		@(posedge clock);
	endtask 
	
	// Task to clear internal values
	task clearValues ();
		load <= 0;
		clear <= 1;
		carry_enable <= 0;
		data_in <= '0;
		weight <= '0;
		result_carry <= '0;
		partialSum <= '0;
		expectedResult <= '0;
		$display("Clearing All Values...");
		@(posedge clock);
		clear <= 0;
		@(posedge clock);
	endtask 
	
	// Function to display values based on display_t enum
	function void showValueFor(display_t show);
		if (show == INPUTS) $display("Data In: %0d, Weight: %0d", data_in, weight);
		else if (show == MULTIPLICATION) $display("Multipled %0d by %0d, %0d times", data_in, weight, accumulate.numOfMults);
		else if (show == RESULT) $display("Result: %0d, Partial Sum: %0d\n", result, partialSum);
		else if (show == ACCUMULATOR) $display("Accumulator: %0d", DUT.accumulator);
		else if (show == ALL) begin 
			$display("***********************************************");
			$display("Data In: %0d, Weight: %0d, Load: %0d, Carry: %0d\nClear: %0d, Accumaltor: %0d, Result Carried: %0d",
						data_in, weight, load, carry_enable, clear, DUT.accumulator, result_carry);
			$display("***********************************************");
		end
	endfunction 
	
	// Continuous monitoring of carry outputs
	always @(posedge clock) begin 
		assert (weight_carry == weight) 
		else begin $error("Weight did not carry through!"); errors ++;end
		
		assert (data_in_carry == data_in)
		else begin $error("Data In did not carry through!"); errors++; end
	end
	
	// Main testbench stimulus
	initial begin
		$display("***********************************************");
		$display("Beginning Testbench, reseting DUT ...");
		$display("***********************************************");
		resetDUT();
		@(posedge clock);
		
		repeat(7) begin 
			accumulate($urandom_range(1,10),$urandom_range(1,32) ,$urandom_range(1,32)); 
		end
		
		clearValues(); // Clear internal values
      showValueFor(ALL); // Display values after clearing
      setCarry(); // Test carry functionality
		
		repeat(4) begin 
			accumulate($urandom_range(1,10),$urandom_range(1,32) ,$urandom_range(1,32)); 
		end
		
		setCarry();
		showValueFor(ALL);
		
		repeat(3) begin 
			accumulate($urandom_range(1,10),$urandom_range(1,32) ,$urandom_range(1,32)); 
		end
		
		clearValues();
		setCarry();
		showValueFor(ALL);
		
		$display("***********************************************");
		if (errors != 0) $display("Testbench failed with %d errors!",errors);
		else $display("Testbench passed!",);
		$display("***********************************************");
		$finish;
	end 

endmodule : PE_TB
