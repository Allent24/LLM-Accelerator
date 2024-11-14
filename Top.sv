`timescale 1 ps / 1 ps

/* 
* Top Level Module for LLM Accelerator
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator
* Updated: November 14, 2024
*
* Description:
* This top-level module instantiates the Input Buffer, Weight Buffer, and Systolic Array modules.
* It connects these components using the Design Interface and manages the control signals
* for the overall operation of the accelerator.
*
* Inputs:
    * clock: Clock signal.
    * reset_n: Asynchronous reset signal (active low).
    * load: Load signal to enable data loading.
    * clear: Clear signal to reset buffers and accumulators.
*
* Outputs:
    * systolic_array_output_data: Result data from the systolic array.
*/

module Top #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (
    input logic CLOCK_50,                   
    input logic reset_n,                 
    input logic load,                   
    input logic clear,                  
    output logic [WIDTH-1:0] systolic_array_output_data [SIZE-1:0]
);

    DesignInterface #(WIDTH, SIZE, ADDR) TOP(CLOCK_50);

    // Assign top-level inputs to the interface
    assign TOP.reset_n = reset_n;
    assign TOP.control.systolic_array_load = load;
    assign TOP.control.systolic_array_clear = clear;

    InputBuffer #(WIDTH, SIZE, ADDR) input_buffer_inst (
        .IB(TOP)
    );

    WeightBuffer #(WIDTH, SIZE, ADDR) weight_buffer_inst (
        .WB(TOP)
    );

    SystolicArray #(WIDTH, SIZE) systolic_array_inst (
        .SA(TOP)
    );

    // Assign output from the Systolic Array
    assign systolic_array_output_data = TOP.data_path.systolic_array_output_data;

endmodule : Top