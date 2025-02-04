/* 
* Design of Control Unit for Control Signals in each State
* Created By: Santino DeAngelis
* Project: LLM Accelerator
* Updated: November 29, 2024
*
* Description:
* This control unit defines the control signals for controlling the Input/Weight/Output Buffers, Controller, and 
* the Systolic Array in a matrix multiplication accelerator design, for each state. It provides the necessary signals 
* for reading, writing, and controlling the input data and addresses for efficient processing by the 
* Systolic Array. This is initially built for a 2x2 Systolic Array, but is designed to easily be scaled-up.
*/

module ControlUnit #(parameter WIDTH = 8, SIZE = 6, ADDR = $clog2(SIZE))
 (  input logic clock, reset_n,
	output logic ib_rd1, ib_wr1, ib_wr2,
	output logic sa_clear, sa_load,
	output logic sa_carry_en [SIZE-1:0],
	output logic [ADDR-1:0] in_addr_in1,
	output logic [ADDR-1:0] in_addr_in2,  
	output logic [WIDTH-1:0] in_data_in1 [SIZE-1:0],
	output logic [WIDTH-1:0] in_data_in2 [SIZE-1:0], 
    output logic wb_rd1, wb_wr1, wb_wr2,
    output logic [ADDR-1:0] wb_addr_in1,	   
    output logic [ADDR-1:0] wb_addr_in2,
    output logic [WIDTH-1:0] wb_data_in1 [SIZE-1:0],
    output logic [WIDTH-1:0] wb_data_in2 [SIZE-1:0]
     );
    
    typedef enum logic [1:0] { READ, WRITE, PASS, CLEAR } state_t;                              
    state_t state, next_state;

    logic stop_read, stop_write, stop_pass, stop_clear; // 1-bit 
    assign stop_read = (in_addr_in1 == SIZE)? 1:0 ;
    // logic stop_WRITE = ( NOT NEEDED, should be a simple change);
    assign stop_pass = (sa_carry_en == SIZE)? 1:0 ;
    // assign stop_clear = ( NOT NEEDED, should be an instantaneous change );
    logic [WIDTH-1:0] count;    // Count to increment the addresses or carry enables as needed for the state
    always_ff @ (posedge clock or negedge reset_n) begin
        if(reset_n) 
            count <= 0;
        else 
            count <= count + 1;
    end 

    always_ff @ (posedge clock or negedge reset_n) begin
        if(reset_n) 
            sa_carry_en <= 0;
        else
            sa_carry_en <= sa_carry_en + 1;
        end         

    always_ff @ (posedge clock or negedge reset_n) begin
        if(!reset_n) begin      // initialize Control Signals
            ib_rd1 <= 0;
            ib_wr1 <= 0;
            ib_wr2 <= 0;
            sa_clear <= 0;
            sa_carry_en <= '{default:'0};
            sa_load <= 0;
            in_addr_in1 <= '{default:'0};
            in_addr_in2 <= '{default:'0};
        end else begin
            state <= next_state;
    
            unique case (state)
            READ : begin
        ib_rd1 <= 1;
        ib_wr1 <= 0;
        ib_wr2 <= 0;
        sa_clear <= 0;
        sa_carry_en <= 0;
        sa_load <= 0;
        in_addr_in1 <= in_addr_in1 + count;
        in_addr_in2 <= in_addr_in2 + count;
                end
            WRITE : begin
        ib_rd1 <= 0;
        ib_wr1 <= 1;
        ib_wr2 <= 1;
        sa_clear <= 0;
        sa_carry_en <= 0;
        sa_load <= 0;
        in_addr_in1 <= 1;
        in_addr_in2 <= 1;
                end
            PASS : begin
        ib_rd1 <= 0;
        ib_wr1 <= 0;
        ib_wr2 <= 0;
        sa_clear <= 0;
        sa_carry_en <= 1;
        sa_load <= 1;
        in_addr_in1 <= 1;
        in_addr_in2 <= 1;
                end
            CLEAR : begin
        ib_rd1 <= 0;
        ib_wr1 <= 0;
        ib_wr2 <= 0;
        sa_clear <= 1;
        sa_carry_en <= 0;
        sa_load <= 0;
        in_addr_in1 <= 0;
        in_addr_in2 <= 0;
                end
            endcase
        end
    end
          
always_comb begin
    case(state)
    READ: next_state = (stop_read)? PASS:READ;
    WRITE: next_state = (stop_write)? CLEAR:WRITE;
    PASS: next_state = (stop_pass)? WRITE:PASS;
    CLEAR: next_state = (stop_clear)? READ:CLEAR;
    endcase
end      
    
endmodule : ControlUnit
