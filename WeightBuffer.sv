`timescale 1 ps / 1 ps

/* 
* Weight Buffer Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 26, 2024
*
* Description:
* This module implements a weight buffer to store and pipeline weight data.
* The module contains an array of vectors and uses a generate block to instantiate multiple Vector submodules 
* that interface with provided addresses and data ports for read and write operations.
*
* Inputs:
*   - clock: Clock signal for synchronous operations.
*   - reset_n: Active low reset signal.
*   - wb_addr_in1: Address lines for accessing vector data (port A).
*   - wb_addr_in2: Address lines for accessing vector data (port B).
*   - wb_data_in1: Data input for write operations (port A).
*   - wb_data_in2: Data input for write operations (port B).
*   - wb_rd1: Read enable signal for the vectors.
*   - wb_wr1: Write enable signal for port A.
*   - wb_wr2: Write enable signal for port B.
*
* Outputs:
*   - wb_data_out: Output data lines from the pipelined vector data.
*/

module WeightBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface.WeightBuffer WB); 
    logic [WIDTH-1:0] vector_data [SIZE-1:0];
    logic [WIDTH-1:0] vector_data_pipeline [SIZE-1:0];
    
    genvar i;
    generate 
        for (i = 0; i < SIZE; i++) begin : VECTOR
            // Instantiation of the Vector module for each vector element in the buffer
            Vector #(WIDTH, ADDR) ROWS
                (.address_a     (WB.wb_addr_in1),      // Address for port A
                .address_b      (WB.wb_addr_in2),  	 // Address for port B
                .clock          (WB.clock),            // Clock signal
                .data_a         (WB.wb_data_in1[i]),   // Data input for write port A
                .data_b         (WB.wb_data_in2[i]),   // Data input for write port B
                .rden_a         (WB.wb_rd1),            // Read enable for port A
                .wren_a         (WB.wb_wr1),           // Write enable for port A
                .wren_b         (WB.wb_wr2),           // Write enable for port B
                .q_a            (vector_data[i]));     // Output data from port A
        end
    endgenerate 
    
    // Pipeline the vector data
    always_ff @(posedge WB.clock or negedge WB.reset_n) begin 
        if (!WB.reset_n) 
            vector_data_pipeline <= '{default: '0};    // Reset the pipeline to default values
        else 
            vector_data_pipeline <= vector_data;       // Update pipeline data on clock edge
    end 
    
    // Assign the pipelined data to the output
    assign WB.wb_data_out = vector_data_pipeline; 

endmodule : WeightBuffer


