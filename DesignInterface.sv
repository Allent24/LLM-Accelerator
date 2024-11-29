/* 
* Design Interface for Input/Weight/Output Buffers, Controller, and Systolic Array
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator
* Updated: November 26, 2024
*
* Description:
* This interface defines the signals used for controlling and managing the Input/Weight/Output Buffers, Controller, and 
* the Systolic Array in a matrix multiplication accelerator design. It provides the necessary signals 
* for reading, writing, and controlling the input data and addresses for efficient processing by the 
* Systolic Array.
*/

interface DesignInterface #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (input logic clock);
    // Shared Signals
    logic reset_n; // Shared reset signal (active low)

	// Control Signals Group 
    logic ib_rd1;             // Input Buffer read enable
    logic ib_wr1;             // Input Buffer write enable for Port 1
    logic ib_wr2;             // Input Buffer write enable for Port 2
    
    logic wb_rd1;             // Weight Buffer read enable
    logic wb_wr1;             // Weight Buffer write enable for Port 1
    logic wb_wr2;             // Weight Buffer write enable for Port 2
    
    logic sa_load;            // Systolic Array load enable
    logic sa_clear;           // Systolic Array clear enable
	 logic sa_data_ready;		// Systolic Array ready for data transfer
    logic sa_carry_en [SIZE-1:0]; // Systolic Array carry enable
	 
	 logic ob_ready_to_recv;	// Output Buffer ready to receive data

	 // Data Path Signals Group
    logic [WIDTH-1:0] ib_data_in1 [SIZE-1:0];  // Input Buffer data input (Port 1)
    logic [WIDTH-1:0] ib_data_in2 [SIZE-1:0];  // Input Buffer data input (Port 2)
    logic [WIDTH-1:0] ib_data_out [SIZE-1:0];  // Input Buffer data output
	 
	 logic [ADDR-1:0] ib_addr_in1;   // Input Buffer address input (Port 1)
    logic [ADDR-1:0] ib_addr_in2;   // Input Buffer address input (Port 2)

    logic [WIDTH-1:0] wb_data_in1 [SIZE-1:0];  // Weight Buffer data input (Port 1)
    logic [WIDTH-1:0] wb_data_in2 [SIZE-1:0];  // Weight Buffer data input (Port 2)
    logic [WIDTH-1:0] wb_data_out [SIZE-1:0];  // Weight Buffer data output
	 
	 logic [ADDR-1:0] wb_addr_in1;   // Weight Buffer address input (Port 1)
    logic [ADDR-1:0] wb_addr_in2;   // Weight Buffer address input (Port 2)
        
    logic [WIDTH-1:0] ob_data_out [SIZE-1:0]; // Output Buffer data output
	 
	 logic [WIDTH-1:0] sa_data_out [SIZE-1:0]; // Systolic Array data output

    // Modport for the Input Buffer
    modport InputBuffer (
		input  clock, reset_n,
		input  ib_rd1, 
		input  ib_wr1, 
		input  ib_wr2,
		input  ib_data_in1, 
		input  ib_data_in2,
		input  ib_addr_in1, 
		input  ib_addr_in2,
		output ib_data_out
    );

    // Modport for the Weight Buffer
    modport WeightBuffer (
		input  clock, reset_n,
		input  wb_rd1,
		input  wb_wr1,
		input  wb_wr2,
		input  wb_data_in1,
		input  wb_data_in2,
		input  wb_addr_in1,
		input  wb_addr_in2,
		output wb_data_out
    );

    // Modport for the Output Buffer
    modport OutputBuffer (
		input  clock, reset_n,
		input  sa_data_out,
		input  sa_data_ready,
		output ob_data_out,
		output ob_ready_to_recv
    );

    // Modport for the Systolic Array
    modport SystolicArray (
		input  clock, reset_n,
      input  sa_load,
      input  sa_clear,
      input  sa_carry_en,
		input  ib_data_out,
		input  wb_data_out,
		output sa_data_out 
    );
	 
	 // Modport for the Controller
	 modport Controller (
		input  clock, reset_n,
		input  ob_ready_to_recv,
		output ib_rd1, 
		output ib_wr1, 
		output ib_wr2,
		output ib_addr_in1, 
		output ib_addr_in2,
		output wb_rd1,
		output wb_wr1,
		output wb_wr2,
		output wb_addr_in1,
		output wb_addr_in2,
		output sa_load,
      output sa_clear,
      output sa_carry_en,
		output sa_data_ready
	 );
    
endinterface : DesignInterface

