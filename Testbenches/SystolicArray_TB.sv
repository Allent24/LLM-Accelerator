/* 
* Systolic Array Testbench
* Created By: Jordi Marcial Cruz
* Updated: March 7th, 2025
*
* Description:
* This testbench verifies the functionality of a Systolic Array module. 
* It provides stimuli to the Systolic Array and checks the output against expected results.
* The testbench utilizes randomized input data and supports parameterized array dimensions.
*/

`timescale 1 ps / 1 ps

virtual class Base  
  #(parameter WIDTH = 32,
    		  SIZE = 8);
  
endclass : Base

class Driver extends Base;
  randc bit [WIDTH-1:0] weight_data [SIZE-1:0];
  randc bit [WIDTH-1:0] input_data  [SIZE-1:0]; 
  
  constraint weight_data_range {
    foreach(weight_data[index])
      weight_data[index] inside { [0:99] }; 
  }
  
  constraint input_data_range {
    foreach(input_data[index]) 
      input_data[index] inside { [0:99] };
  }
  
  function new();
    this.weight_data = '{default: '0};
    this.input_data = '{default: '0};
  endfunction;
  
endclass : Driver

class Scoreboard extends Base;
  static int errors;
  bit [WIDTH-1:0] expected_partial_sums [SIZE-1:0][SIZE-1:0];
  logic [WIDTH-1:0] actual_partial_sums [SIZE-1:0] [$];
  
  function new();
	this.errors = 0;
    this.expected_partial_sums = '{default: '0};
  endfunction 
  
  function void f_accumulate_partial_sums (
    input int row,
    input logic [WIDTH-1:0] input_data [SIZE-1:0], 
    input logic [WIDTH-1:0] weight_data [SIZE-1:0]);
    
    for (int col = 0; col < SIZE; col++) begin
      this.expected_partial_sums[row][col] = this.expected_partial_sums[row][col] + (input_data[row] * weight_data[col]);
    end
  endfunction
  
  function void f_carry_result(input logic [WIDTH-1:0] sum [SIZE-1:0], input int row);
     this.actual_partial_sums[row].push_back(sum[row]);
  endfunction 
  
  function void f_check_results();
    logic [WIDTH-1:0] returned_sum;
    for (int row = 0; row < SIZE; row++) begin
      for (int col = SIZE - 1; col > -1; col--) begin 
        returned_sum = this.actual_partial_sums[row].pop_front();
        if (returned_sum !== this.expected_partial_sums[row][col]) 
        	begin 
            $error("Expected PE[%0d][%0d] result: %0d does not match result: %0d",
                    row, col, this.expected_partial_sums[row][col], returned_sum);
            this.errors++; 
            end
        end
      end
  endfunction
  
  function void f_clear_partial_sum();
    this.expected_partial_sums = '{default: '0};
  endfunction 
  
  function void f_check_testbench_errors();
    if (this.errors > 0) begin 
      $display("\nTestbench failed with %0d errors!", this.errors);
    end else begin 
      $display("\nTestbench passed!");
    end
  endfunction 
  
endclass : Scoreboard

module SystolicArray_TB
  #(parameter WIDTH = 32, 
                SIZE = 8);

    bit clock, reset_n;
    DesignInterface #(WIDTH, SIZE) SA_Interface(clock);

    SystolicArray #(WIDTH, SIZE) DUT (
        .SA(SA_Interface.SystolicArray)
    );

    typedef enum int {INPUTS, RANDOMIZE, RESULT, ROWS, CLEAR} display_t;
  
  	Scoreboard sb = new();
  	Driver dr = new();

    initial begin 
        clock = 1;
        forever #5 clock = ~clock;
    end

    task automatic t_reset_dut();
		SA_Interface.reset_n = 0;
        SA_Interface.sa_load = 0;       
        SA_Interface.sa_clear = 0;      
        SA_Interface.sa_carry_en = '{default: '0};
        SA_Interface.wb_data_out = '{default: '0};
        SA_Interface.ib_data_out = '{default: '0};
        #10;
        SA_Interface.reset_n = 1;
    endtask 
  
    task automatic t_clear_array();
        SA_Interface.sa_clear <= 1;                
        f_show_value_for(CLEAR);
      	sb.f_clear_partial_sum();
        @(posedge clock);
        SA_Interface.sa_clear <= 0;               
    endtask 
  
    task automatic t_carry_results();
        for (int col = SIZE - 1; col > -1; col--) begin
            for (int row = 0; row < SIZE; row++) begin 
              sb.f_carry_result(SA_Interface.sa_data_out, row);
            end
            $display("Row Data for Clock Edge %0d", SIZE - 1 - col);
            f_show_value_for(ROWS);
            SA_Interface.sa_carry_en[col] <= 1; 			
            @(posedge clock);
        end
    endtask 
  
    task automatic t_input_data();
        dr.randomize();

        for (int row = 0; row < SIZE; row++) begin
          SA_Interface.wb_data_out[row] <= dr.weight_data[row];   
          SA_Interface.ib_data_out[row] <= dr.input_data[row];   
          sb.f_accumulate_partial_sums(row, dr.input_data, dr.weight_data);
        end

        @(posedge clock);
    endtask 

  	function void f_show_value_for(display_t show);
        if (show == ROWS) begin
            for (int row = 0; row < SIZE; row++) begin 
                $display("Output Data Row %0d: %0d", row, SA_Interface.sa_data_out[row]); 
            end
            $display("***********************************************");
        end else if (show == CLEAR) begin
            $display("Clearing all PE Partial Sums in the Systolic Array");
            $display("***********************************************");
        end
    endfunction 

    initial begin 
        $display("***********************************************");
        $display("Beginning Testbench, resetting DUT...");
        $display("***********************************************");
        t_reset_dut();

        @(posedge clock);
        repeat (10) begin 
            t_input_data();
        end
        
        SA_Interface.sa_load <= 1;           
        @(posedge clock);
        t_carry_results();
        
        repeat (10) begin 
          @(posedge clock);
        end

        sb.f_check_results();

        t_clear_array();
		  
      	sb.f_check_testbench_errors();
      
        $finish;
    end

endmodule : SystolicArray_TB 
