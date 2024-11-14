/* 
* Design Interface for Input/Weight/Output Buffers, Controller, and Systolic Array
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator
* Updated: November 14, 2024
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
    typedef struct {
        logic input_buffer_read;            // Read enable for Input Buffer
        logic input_buffer_write1;          // Write enable for Input Buffer Port 1
        logic input_buffer_write2;          // Write enable for Input Buffer Port 2
        
        logic weight_buffer_read;           // Read enable for Weight Buffer
        logic weight_buffer_write1;         // Write enable for Weight Buffer Port 1
        logic weight_buffer_write2;         // Write enable for Weight Buffer Port 2
        
        logic systolic_array_load;          // Load enable for Systolic Array
        logic systolic_array_clear;         // Clear enable for Systolic Array
        logic systolic_array_carry_enable [SIZE-1:0]; // Carry enable for Systolic Array elements
    } ControlSignals;

    ControlSignals control;

    // Data Path Signals Group
    typedef struct {
        // Input Buffer Data and Address Signals
        logic [WIDTH-1:0] input_buffer_data1 [SIZE-1:0]; // Data for Input Buffer (Port 1)
        logic [WIDTH-1:0] input_buffer_data2 [SIZE-1:0]; // Data for Input Buffer (Port 2)
        logic [ADDR-1:0] input_buffer_addr1 [SIZE-1:0];  // Address for Input Buffer (Port 1)
        logic [ADDR-1:0] input_buffer_addr2 [SIZE-1:0];  // Address for Input Buffer (Port 2)
        logic [WIDTH-1:0] input_buffer_output_data [SIZE-1:0]; // Output Data from Input Buffer

        // Weight Buffer Data and Address Signals
        logic [WIDTH-1:0] weight_buffer_data1 [SIZE-1:0]; // Data for Weight Buffer (Port 1)
        logic [WIDTH-1:0] weight_buffer_data2 [SIZE-1:0]; // Data for Weight Buffer (Port 2)
        logic [ADDR-1:0] weight_buffer_addr1 [SIZE-1:0];  // Address for Weight Buffer (Port 1)
        logic [ADDR-1:0] weight_buffer_addr2 [SIZE-1:0];  // Address for Weight Buffer (Port 2)
        logic [WIDTH-1:0] weight_buffer_output_data [SIZE-1:0]; // Output Data from Weight Buffer

        // Systolic Array Data Signals
        logic [WIDTH-1:0] systolic_array_output_data [SIZE-1:0]; // Output Data from Systolic Array
    } DataPathSignals;

    DataPathSignals data_path;

endinterface : DesignInterface

