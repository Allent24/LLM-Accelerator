`timescale 1 ps / 1 ps

/* 
* Input Buffer Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 16, 2024
*
* Description:
* This module implements an input buffer for storing data inputs to the LLM Accelerator. 
* The buffer takes input from multiple sources, stores the data in a vector, and makes it available to downstream processing elements. 
* It is parameterizable in terms of data width and size, making it flexible to accommodate different system requirements.
*
* Inputs:
*   - ib_addr_in1: Address lines for accessing vector data (port A).
*   - ib_addr_in2: Address lines for accessing vector data (port B).
*   - clock: Clock signal for synchronous operations.
*   - reset_n: Active low reset signal to reset the buffer.
*   - ib_data_in1: Data input for write operations (port A).
*   - ib_data_in2: Data input for write operations (port B).
*   - ib_rd: Read enable signal for accessing the vector data.
*   - ib_wr1: Write enable signal for storing data into the buffer (port A).
*   - ib_wr2: Write enable signal for storing data into the buffer (port B).
*
* Outputs:
*   - ib_data_out: Data output from the input buffer, used for downstream processing.
*/

module InputBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface.InputBuffer IB); 
    logic [WIDTH-1:0] vector_data [SIZE-1:0];
    logic [WIDTH-1:0] vector_data_pipeline [SIZE-1:0];
    
    genvar i;
    generate 
        for (i = 0; i < SIZE; i++) begin : VECTOR
            // Instantiate Vector module for each element in the input buffer
            Vector #(WIDTH, ADDR) ROWS
                (.address_a      (IB.ib_addr_in1[i]),     // Address input for port A
                 .address_b      (IB.ib_addr_in2[i]),     // Address input for port B
                 .clock          (IB.clock),              // Clock signal for synchronization
                 .data_a         (IB.ib_data_in1[i]),     // Data input for write operation (port A)
                 .data_b         (IB.ib_data_in2[i]),     // Data input for write operation (port B)
                 .rden_a         (IB.ib_rd1),              // Read enable signal
                 .wren_a         (IB.ib_wr1),             // Write enable signal for port A
                 .wren_b         (IB.ib_wr2),             // Write enable signal for port B
                 .q_a            (vector_data[i]));       // Output data from the buffer
        end
    endgenerate 
    
    // Sequential logic for pipelining the vector data
    always_ff @(posedge IB.clock or negedge IB.reset_n) begin 
        if (!IB.reset_n) 
            vector_data_pipeline <= '{default: '0};    // Reset the pipeline to default values
        else 
            vector_data_pipeline <= vector_data;       // Update pipeline data on clock edge
    end 
    
    // Assign the pipelined data to the output
    assign IB.ib_data_out = vector_data_pipeline;

endmodule : InputBuffer


