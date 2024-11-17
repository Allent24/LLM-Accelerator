`timescale 1 ps / 1 ps

/* 
* Systolic Array Testbench
* Created By: Jordi Marcial Cruz
* Project: LLM Accelerator 
* Updated: November 16, 2024
*
* Description:
* This testbench verifies the functionality of a Systolic Array module. 
* It provides stimuli to the Systolic Array and checks the output against expected results.
* The testbench utilizes randomized input data and supports parameterized array dimensions.
* Key features include:
    * Resetting the DUT.
    * Applying random input data.
    * Calculating expected outputs.
    * Capturing output data.
    * Clearing the systolic array.
    * Verifying results against expected values.
*/

module SystolicArray_TB
    #(parameter WIDTH = 8, // Output for SA must be 22 bits or greater for an 8-bit 64x64 matrix
                SIZE = 8);

    bit clock, reset_n;
    // Instantiate the Design Interface
    DesignInterface #(WIDTH, SIZE) SA_Interface(clock);

    // Instantiate the Device Under Test (DUT) with the interface
    SystolicArray #(WIDTH, SIZE) DUT (
        .SA(SA_Interface.SystolicArray) // Use SystolicArray modport
    );

    // Signals used for random stimulus
    bit [WIDTH-1:0] w [SIZE-1:0];
    bit [WIDTH-1:0] x [SIZE-1:0];

    // Internal testbench signals for verification
    logic [WIDTH-1:0] partialSum [SIZE-1:0] [SIZE-1:0];
    logic [WIDTH-1:0] storedResults [SIZE-1:0][$];
    int errors = 0;

    // Enum for controlling display output
    typedef enum int {INPUTS, RANDOMIZE, RESULT, ROWS, CLEAR} display_t;

    // Clock generation
    initial begin 
        clock = 1;
        forever #5 clock = ~clock;
    end

    // Task to reset the DUT
    task resetDUT();
        begin
            SA_Interface.reset_n = 0;
            SA_Interface.sa_load = 0;       
            SA_Interface.sa_clear = 0;      
            partialSum = '{default: '0};
            SA_Interface.sa_carry_en = '{default: '0};
            SA_Interface.wb_data_out = '{default: '0};
            SA_Interface.ib_data_out = '{default: '0};
            #10;
            SA_Interface.reset_n = 1;
        end
    endtask

    // Function to randomize input data
    function automatic void randomizeInputs();
        for (int index = 0; index < SIZE; index++) begin 
            w[index] = $urandom_range(1, 255);
            x[index] = $urandom_range(1, 255);
        end
    endfunction 

    // Task to apply input data to the DUT
    task automatic inputData();
        randomizeInputs();

        for (int row = 0; row < SIZE; row++) begin
            SA_Interface.wb_data_out[row] <= w[row];   
            SA_Interface.ib_data_out[row] <= x[row];   
            for (int col = 0; col < SIZE; col++) begin
                partialSum[row][col] <= partialSum[row][col] + (x[row] * w[col]);
            end
        end

        @(posedge clock);
    endtask 

    // Task to capture and display output data
    task automatic carryResults();
        for (int col = SIZE - 1; col > -1; col--) begin
            for (int row = 0; row < SIZE; row++) begin 
                storedResults[row].push_back(SA_Interface.sa_data_out[row]);
            end
            $display("Row Data for Clock Edge %0d", SIZE - 1 - col);
            showValueFor(ROWS);
            SA_Interface.sa_carry_en[col] <= 1; 			
            @(posedge clock);
        end
    endtask

    // Task to clear the systolic array
    task automatic clearArray();
        SA_Interface.sa_clear <= 1;                
        partialSum <= '{default: '0};
        showValueFor(CLEAR);
        @(posedge clock);
        SA_Interface.sa_clear <= 0;               
    endtask

    // Function to check the DUT's output against expected results
    function automatic void checkResults();
        int returnedResult;
        for (int row = 0; row < SIZE; row++) begin
            for (int col = SIZE - 1; col > -1; col--) begin 
                returnedResult = storedResults[row].pop_front();
                // $display("returnedResult: %0d", returnedResult);
                assert (returnedResult == partialSum[row][col]) 
                else begin 
                    $error("Expected PE[%0d][%0d] result: %0d does not match result: %0d",
                            row, col, partialSum[row][col], returnedResult);
                    errors++; 
                end
            end
        end
    endfunction

    // Function to display values based on the display_t enum
    function automatic void showValueFor(display_t show);
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

    // Main testbench stimulus
    initial begin 
        $display("***********************************************");
        $display("Beginning Testbench, resetting DUT...");
        $display("***********************************************");
        resetDUT();

        @(posedge clock);
        repeat (10) begin 
            inputData();
        end
        
        SA_Interface.sa_load <= 1;           
        @(posedge clock);
        carryResults();
        
        repeat (10) begin 
            @(posedge clock);
        end

        checkResults();

        clearArray();
        checkResults();
		  
        $display("***********************************************");
        if (errors != 0) $display("Testbench failed with %0d errors!", errors);
        else $display("Testbench passed!");
        $display("***********************************************"); 
        $finish;
    end

endmodule : SystolicArray_TB 
