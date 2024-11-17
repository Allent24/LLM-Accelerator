`timescale 1 ps / 1 ps

/* 
* Output Buffer Module
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 16, 2024
*
* Description:
* This module implements an output buffer to store results from the LLM Accelerator and facilitate their transfer to other components. 
* The buffer can store multiple vectors and is parameterizable in terms of data width and size, allowing it to accommodate different
* processing requirements.
*
* Inputs:
*   - ob_addr_in1: Address lines to specify which part of the output buffer to read or write.
*   - clock: Clock signal for synchronous operations.
*   - reset_n: Active low reset signal to reset the buffer.
*   - sa_data_out: Data input from the systolic array output.
*   - ob_rd: Read enable signal to allow reading from the output buffer.
*   - ob_wr1: Write enable signal for storing data from the systolic array into the buffer.
*
* Outputs:
*   - ob_data_out: Data output from the output buffer for external usage.
*/

module OutputBuffer #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE)) (DesignInterface.OutputBuffer OB); 
     logic [WIDTH-1:0] array_data [SIZE-1:0];
     logic [WIDTH-1:0] array_data_pipeline [SIZE-1:0];

     genvar i;
     generate 
         for (i = 0; i < SIZE; i++) begin : VECTOR
             // Instantiate Vector module for each vector element in the output buffer
             Vector #(WIDTH, ADDR) ROWS
                 (.address_a     (OB.ob_addr_in1[i]),   // Address input for read/write access
                  .address_b      (),                   // Unused address port
                  .clock          (OB.clock),           // Clock signal for synchronization
                  .data_a         (OB.sa_data_out[i]),  // Data input from systolic array
                  .data_b         (),                   // Unused data port
                  .rden_a         (OB.ob_rd),           // Read enable signal
                  .wren_a         (OB.ob_wr1),          // Write enable signal
                  .wren_b         (),                   // Unused write enable port
                  .q_a            (OB.ob_data_out[i])); // Output data from the buffer
         end
     endgenerate 

     // The FIFO instantiation if an output FIFO is required for data streaming
     // OB_FIFO #(WIDTH, SIZE) FIFO (
     // .clock(), 
     // .reset_n(), 
     // .read(), 
     // .write(),
     // .data_in(),
     // .almost_empty(), 
     // .empty(),
     // .almost_full(), 
     // .full(),
     // .data_out());
		
     // Sequential logic for pipelining output data 
     // always_ff @(posedge OB.clock or negedge OB.reset_n) begin 
     //    if (!OB.reset_n) array_data_pipeline <= '{default: '0};
     //    else array_data_pipeline <= array_data;
     // end
		
endmodule : OutputBuffer

