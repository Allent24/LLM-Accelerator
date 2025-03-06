/* 
* FIFO Buffer Testbench
* Created By: Jordi Marcial Cruz
* Updated: March 4th, 2025
*
* Description:
* This testbench verifies the functionality of a FIFO buffer module by applying various stimuli and checking the expected behavior. 
* It includes a scoreboard to track expected values, monitors for data mismatches, and asserts properties using bind-based assertions.
* Error tracking and final verification ensure correctness, and a structured clocking mechanism ensures accurate sampling of signals.
*/

`timescale 1ps/1ps

class Fifo_Scoreboard #(parameter WIDTH = 32);
  bit [WIDTH-1:0] expected_data_q[$];
  bit concurrent;			// Flag for concurrent read and write with 0 cycle delays 
  int errors;				// Error counter for keeping track of total testbench errors
  
  // Constructor for new instance  
  function new();
    this.errors = 0;		
    this.concurrent = 0;	
  endfunction 
  
  // Function to push data onto the queue
  function void f_push_expected_data(logic [WIDTH-1:0] data);
    if (!this.concurrent) expected_data_q.push_back(data);
  endfunction

  // Function to pop data from the queue and compare with the FIFO output data
  function void f_check_data_against_expected(logic [WIDTH-1:0] actual_data_out);
    if (!this.concurrent) begin 
      if (expected_data_q.size() == 0) begin
        $warning("[%0t] Read occurred but scoreboard queue is empty!", $time);
      end 
      
      else begin
        bit [WIDTH-1:0] expected_data;
        expected_data = expected_data_q.pop_front();
        
        if (actual_data_out !== expected_data) begin
          $error("[%0t] Data mismatch! Got %0d, expected %0d", 
                  $time, actual_data_out, expected_data);
          this.errors++;
        end
      end
    end
    
    else begin 
      if (actual_data_out !== 'z) begin
          $error("[%0t] Data mismatch! Got %0d, expected z", 
                  $time, actual_data_out);
          this.errors++;
        end
      end
  endfunction
  
    // Function to check total testbench errors at the end of the simulation
  function void f_check_testbench_errors();
    if (errors > 0) begin 
      $display("\nTestbench failed with %0d errors!", this.errors);
    end else begin 
      $display("\nTestbench passed!");
    end
  endfunction 
  
endclass

module Fifo_Buffer_TB
  #(parameter WIDTH = 32,
    parameter DEPTH = 8);

  logic clk;
  logic reset_n;
  logic read;
  logic write;
  logic [WIDTH-1:0] data_in;
  logic empty;
  logic full;
  logic [WIDTH-1:0] data_out;

  Fifo_Buffer #(WIDTH, DEPTH) DUT (.*);		// FIFO Buffer instantiation 
  
  // Clocking block used for sampling and driving signals  
  clocking cb @(posedge clk);
    default input #1 output #1;	
    input data_out, empty, full;
    output read, write, data_in;
  endclocking;
  
  default clocking cb;	// Set cb as default clock for testbench

  Fifo_Scoreboard #(WIDTH) sb = new;	// New instance of FIFO Scoreboard Class 

  // Bound Concurrent Assertions to FIFO design module 
  bind Fifo_Buffer Fifo_Assertions #(WIDTH, DEPTH) DUT_Assertions (
    .clk        (clk),
    .reset_n    (reset_n),
    .read       (read),
    .write      (write),
    .data_in    (data_in),
    .cntr       (cntr),
    .wr_ptr     (wr_ptr),
    .rd_ptr     (rd_ptr),
    .valid_read (valid_read),
    .valid_write(valid_write),
    .empty      (empty),
    .full       (full),
    .data_out   (data_out)
  );

  initial begin
    clk = 1;
    forever #5 clk = ~clk;
  end

  task automatic t_reset_dut();
    reset_n = 0;
    cb.read  <= 0;
    cb.write <= 0;
    cb.data_in <= 0;

    #10; 
    reset_n = 1;
  endtask

  // Task to write to FIFO 
  task automatic t_write_to(input logic [WIDTH-1:0] wr_data);
    cb.write   <= 1;
    cb.data_in <= wr_data;
    @(cb);
    sb.f_push_expected_data(wr_data);
    cb.write   <= 0;
    cb.data_in <= '0;
    @(cb);
  endtask

  // Task to read from FIFO 
  task automatic t_read_from();
    cb.read <= 1;
    @(cb);
    sb.f_check_data_against_expected(data_out);
    cb.read <= 0;
    @(cb);
  endtask

  // Task to read and write from/to FIFO with set cycle delay
  task automatic t_concurrent_rd_wr(
    input int rd_delay,
    input int wr_delay,
    input logic [WIDTH-1:0] wr_data
  );
    if (wr_delay == rd_delay) begin
      sb.concurrent = 1;
    end
    
    fork
      begin
        repeat(wr_delay) @(cb);
        t_write_to(wr_data);
      end
      begin
        repeat(rd_delay) @(cb);
        t_read_from();
      end
    join
    
    sb.concurrent = 0;
  endtask
    
  always @(cb) begin 
    $display("[%0d] \t Read : %0d \t Write : %0d \t Data In : %d \t Data Out : %d", $stime,
             read, write, data_in, data_out); 
  end 

  initial begin
    $display("Beginning test bench, resetting DUT...");
    t_reset_dut();
    @(cb);

    $display("\nBeginning direct test cases...");
    t_write_to(32'd100);
    t_read_from();
    t_write_to(32'd11);
    t_read_from();
    t_write_to(32'd1111);
    t_read_from();

    $display("\nWriting to fill fifo...");
    repeat (DEPTH) begin
      t_write_to($urandom_range(1, 255));
    end

    $display("\nReading until fifo empty...");
    repeat (DEPTH) begin
      t_read_from();
    end

    $display("\nBeginning concurrency test cases...");
    t_concurrent_rd_wr(0, 0, 32'd99);		// Edge case, read and write concurrently, expecting z 
    t_concurrent_rd_wr(0, 1, 32'd1010);		// Edge case, reading when FIFO is empty, expecting warning
    t_concurrent_rd_wr(1, 0, 32'd1);

    $display("\nReading all values from FIFO...");
    while (!empty) t_read_from();			// Read FIFO till empty

    sb.f_check_testbench_errors();			// Check for total errors 
    $display("Test bench has finished");
    $finish;
  end

endmodule : Fifo_Buffer_TB
