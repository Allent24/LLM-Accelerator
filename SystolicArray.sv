`timescale 1 ps / 1 ps

/* 
* Systolic Array Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 16, 2024
*
* Description:
* This module implements a Systolic Array of Processing Elements (PEs). 
* The array performs matrix multiplication in a parallel and pipelined manner, allowing for efficient computation. 
* The systolic array processes data inputs in a wave-like manner across the array of PEs, enabling effective data reuse and high throughput.
*
* Inputs:
*   - clock: Clock signal to synchronize the operations of the systolic array.
*   - reset_n: Asynchronous reset signal (active low) to reset all PEs.
*   - load: Load signal to enable loading of the PE accumulators.
*   - clear: Clear signal to reset the PE accumulators to default values.
*   - carry_enable: Enable signals to control the carry of results between adjacent PEs.
*   - weight_data: Array of weight values for each row of the systolic array.
*   - input_data: Array of input data values for each column of the systolic array.
*
* Outputs:
*   - output_data: Array of output results from each row of the systolic array.
*/

module SystolicArray #(parameter WIDTH = 8, SIZE = 6) (DesignInterface.SystolicArray SA);
    logic [WIDTH-1:0] weight_down [SIZE:0] [SIZE-1:0];
    logic [WIDTH-1:0] data_in_across [SIZE-1:0] [SIZE:0];
    logic [WIDTH-1:0] result_across [SIZE-1:0] [SIZE:0];

    genvar i, j;
    generate
        for (i = 0; i < SIZE; i++) begin : PE_ROWS
            for (j = 0; j < SIZE; j++) begin : PE_COLUMNS
                // Instantiate the Processing Element (PE) for each row-column intersection
                PE #(WIDTH) PE_inst
                    (.clock           (SA.clock),           // Clock signal
                     .reset_n         (SA.reset_n),         // Asynchronous reset signal (active low)
                     .load            (SA.sa_load),         // Load signal for PE accumulator
                     .clear           (SA.sa_clear),        // Clear signal to reset PE
                     .carry_enable    (SA.sa_carry_en[j]),  // Carry enable signal for chaining PEs
                     .data_in         (data_in_across[i][j]), // Data input to the PE
                     .weight          (weight_down[i][j]),   // Weight input to the PE
                     .result_carry    (result_across[i][j]), // Carry result output from the PE
                     .result          (result_across[i][j+1]), // Result output from the PE to next column
                     .weight_carry    (weight_down[i+1][j]),  // Weight carry to the next row PE
                     .data_in_carry   (data_in_across[i][j+1])); // Data input carry to the next column PE
            end

            // Assign initial values for the first row and column of the array
            always_comb begin
                weight_down[0][i] = SA.wb_data_out[i];      // Initial weight input for row i
                data_in_across[i][0] = SA.ib_data_out[i];   // Initial data input for column i
                SA.sa_data_out[i] = result_across[i][SIZE]; // Output result for row i after processing
            end
        end
    endgenerate

endmodule : SystolicArray

