`timescale 1 ps / 1 ps

module SystolicArray_TB
    #(parameter WIDTH = 32, // Output for SA must be 22 bits or greater for an 8-bit 64x64 matrix
                SIZE = 2);

    logic CLOCK_50, reset_n, load, clear;
    // Instantiate the Design Interface
    DesignInterface #(WIDTH, SIZE) SA_Interface(CLOCK_50);

    // Instantiate the Device Under Test (DUT) with the interface
    SystolicArray #(WIDTH, SIZE) DUT (
        .SA(SA_Interface)
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
        CLOCK_50 = 1;
        forever #5 CLOCK_50 = ~CLOCK_50;
    end

    // Task to reset the DUT
    task resetDUT();
        begin
            SA_Interface.reset_n = 0;
            SA_Interface.systolic_array_load = 0;
            SA_Interface.systolic_array_clear = 0;
            partialSum = '{default: '0};
            SA_Interface.systolic_array_carry_enable = '{default: '0};
            SA_Interface.weight_buffer_output_data = '{default: '0};
            SA_Interface.input_buffer_output_data = '{default: '0};
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
            SA_Interface.weight_buffer_output_data[row] <= w[row];
            SA_Interface.input_buffer_output_data[row] <= x[row];
            for (int col = 0; col < SIZE; col++) begin
                partialSum[row][col] <= partialSum[row][col] + (x[row] * w[col]);
            end
        end

        @(posedge CLOCK_50);
    endtask 

    // Task to capture and display output data
    task carryResults();
        for (int col = SIZE - 1; col > -1; col--) begin
            for (int row = 0; row < SIZE; row++) begin 
                storedResults[row].push_back(SA_Interface.systolic_array_output_data[row]);
            end
            $display("Row Data for Clock Edge %0d", SIZE - 1 - col);
            showValueFor(ROWS);
            SA_Interface.systolic_array_carry_enable[col] <= 1;
            @(posedge CLOCK_50);
        end
    endtask

    // Task to clear the systolic array
    task clearArray();
        SA_Interface.systolic_array_clear <= 1;
        partialSum <= '{default: '0};
        showValueFor(CLEAR);
        @(posedge CLOCK_50);
        SA_Interface.systolic_array_clear <= 0;
    endtask

    // Function to check the DUT's output against expected results
    function void checkResults();
        int returnedResult;
        for (int row = 0; row < SIZE; row++) begin
            for (int col = SIZE - 1; col > -1; col--) begin 
                returnedResult = storedResults[row].pop_front();
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
    function void showValueFor(display_t show);
        if (show == ROWS) begin
            for (int row = 0; row < SIZE; row++) begin 
                $display("Output Data Row %0d: %0d", row, SA_Interface.systolic_array_output_data[row]);
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

        @(posedge CLOCK_50);
        repeat (10) begin 
            inputData();
        end
        
        SA_Interface.systolic_array_load <= 1;
        @(posedge CLOCK_50);
        carryResults();
        
        repeat (10) begin 
            @(posedge CLOCK_50);
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

