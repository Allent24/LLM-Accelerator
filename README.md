# **LLM Accelerator (Attention Module)**  

## **Project Overview**  
This capstone project implements a **hardware accelerator for the Attention Module** in simple Large Language Models (LLMs). Developed by students at **Rowan University** under **PI Dwaipayan Chakraborty** during the Fall 2024 semester, the project focuses on efficient **matrix multiplication** operations, leveraging a **systolic array architecture** to optimize performance. The design is implemented on an **Altera Cyclone V FPGA**, emphasizing modularity, scalability, and energy efficiency.

The core operation accelerated by this design involves matrix-vector multiplication essential for the attention mechanism, using the systolic array's parallel processing capabilities to achieve high throughput and low latency.

---

## **Module Summaries**  

### **1. Top Module**  
- **Purpose**: Serves as the central integration point for all other modules in the LLM Accelerator design.  
- **Features**:  
  - Connects the **Input Buffer**, **Weight Buffer**, **Output Buffer**, **Systolic Array**, and **Controller**.  
  - Orchestrates data flow and synchronization among the subsystems.  
- **Role**: Ensures seamless operation of the entire accelerator pipeline.

---

### **2. Systolic Array Module**  
- **Purpose**: Implements a **32x32 systolic array** for parallel matrix multiplication.  
- **Features**:  
  - **Wave-like Data Propagation**: Processes inputs across rows and columns for efficient computation and data reuse.  
  - **Pipelined Architecture**: Enables high throughput by overlapping computations across rows and columns.  
- **Inputs**:  
  - **Control Signals**: `load`, `clear`, `carry_enable` for managing operations.  
  - **Data Inputs**: `weight_data`, `input_data`.  
- **Outputs**:  
  - `output_data`: Contains results of the matrix multiplication.  
- **Role**: Core computational block for matrix operations, critical for the Attention Module.  
- **Performance Note**: The systolic array achieved a **maximum operating frequency of 450 MHz** for a **32x32, 8-bit wide** configuration when using **Logic Elements (LE)** for multiplication. This significantly outperformed the **DSP block implementation**, which only reached **155 MHz** under the same conditions. The difference in performance is due to the internal architecture of the **Cyclone V FPGA**, where the shorter routing distance to LEs allowed faster multiplication compared to DSP blocks, which require longer routing paths. The **Quartus Timing Analyzer** was used to validate these performance metrics. Notably, this discrepancy was less pronounced in smaller systolic arrays, where the performance of LEs and DSP blocks was comparable.

---

### **3. Processing Element (PE) Module**  
- **Purpose**: Represents the fundamental building block of the systolic array, performing **Multiply-Accumulate (MAC)** operations.  
- **Features**:  
  - **MAC Functionality**: Multiplies input and weight values and accumulates results.  
  - **Inter-PE Communication**: Supports chaining via `carry_enable` for passing intermediate results.  
- **Inputs/Outputs**: Handles data, weight, and carry signals between adjacent PEs.  
- **Role**: Provides localized computation and propagates intermediate results within the systolic array.

---

### **4. LE Multiplier Module**  
- **Purpose**: Performs multiplication of input data and weights within the PEs.  
- **Features**:  
  - Uses **Logic Elements (LE)** instead of DSP blocks, allowing for higher frequency performance.  
  - Configurable widths for input/output data.  
- **Role**: Delivers efficient multiplication operations required for MAC calculations.

---

### **5. DSP Multiplier Module**  
- **Purpose**: Alternative multiplier implementation using **DSP blocks** for higher computational density.  
- **Features**:  
  - Leverages dedicated hardware resources for high-speed multiplication.  
- **Role**: Provides a more resource-efficient option when targeting designs prioritizing area usage.  
- **Performance Note**: The DSP multiplier showed lower maximum operating frequency compared to the LE multiplier for larger systolic arrays due to increased routing distance, making it less efficient for the specific multiplication operations required in the **32x32** array configuration.

---

### **6. Input Buffer Module**  
- **Purpose**: Stores and pipelines input data for feeding into the systolic array.  
- **Features**:  
  - Dual-port access for concurrent read and write operations.  
  - **Pipelined Outputs**: Ensures continuous data flow to prevent stalls.  
- **Inputs/Outputs**: Data (`ib_data_in`, `ib_data_out`) and address (`ib_addr_in`) interfaces.  
- **Role**: Acts as the entry point for input data, ensuring availability for processing.

---

### **7. Weight Buffer Module**  
- **Purpose**: Manages weight data storage and pipelining for the systolic array.  
- **Features**:  
  - Similar to the Input Buffer but tailored for weight data.  
  - Dual-port memory and pipelined outputs.  
- **Role**: Supplies weight values for the matrix multiplication operations.

---

### **8. Output Buffer Module**  
- **Purpose**: Collects and stores results generated by the systolic array.  
- **Features**:  
  - **Ready Signal**: Indicates readiness to receive new data (`ob_ready_to_recv`).  
  - Stores results in a parameterizable buffer, allowing flexibility in data width and size.  
  - Uses a **FIFO mechanism** to manage data streaming and transfer readiness.  
  - **DataController Module**: Controls reading and writing of data, ensuring proper synchronization.  
- **Inputs**:  
  - **Control Signals**: `ob_rd`, `ob_wr1` for read and write operations, `clock` for synchronization, `reset_n` for resetting the buffer.  
  - **Data Inputs**: `sa_data_out` from the systolic array.  
- **Outputs**:  
  - `ob_data_out`: Data output from the output buffer for external use.  
- **Role**: Final stage in the pipeline, managing and buffering results of matrix operations for downstream components.

---

### **9. Data Controller Module**  
- **Purpose**: Manages data flow between the systolic array and the **Output Buffer**.  
- **Features**:  
  - **State Machine**: Manages operations (`WAIT`, `TRANSFER`, `LOAD`) to control reading and writing of data from the buffer.  
  - **FIFO Full/Empty Handling**: Monitors the status of FIFOs (`full`, `empty`) to manage data flow effectively.  
  - **Vector Address Management**: Controls vector addresses for read/write operations in the output buffer.  
- **Role**: Coordinates data transfer from the systolic array output to the output buffer, ensuring data is stored and made available for further processing.  

---

### **10. FIFO Module**  
- **Purpose**: Implements a **First-In-First-Out (FIFO)** buffer for managing data streaming in the **Output Buffer**.  
- **Features**:  
  - **Read/Write Control**: Supports valid read and write operations to manage data transfer within the output buffer.  
  - **Full/Empty Status**: Tracks FIFO status to signal whether data can be read or written.  
  - **Address Management**: Uses internal pointers (`rd_ptr`, `wr_ptr`) to manage read and write addresses.  
- **Role**: Facilitates temporary storage and sequential access to output data, acting as an intermediary between the systolic array and vector storage in the output buffer.

---

### **11. Systolic Array Testbench**  
- **Purpose**: Verifies the functionality of the **Systolic Array Module** by providing various input stimuli and comparing outputs against expected results.  
- **Features**:  
  - **Clock Generation**: Generates a clock signal to drive the DUT (Device Under Test).  
  - **Resetting DUT**: Resets the systolic array to ensure it starts in a known state.  
  - **Randomized Inputs**: Generates random data for weight and input vectors to test the systolic array under different conditions.  
  - **Output Capture and Verification**: Captures results from the DUT and verifies them against expected outputs, reporting any discrepancies.  
  - **Tasks and Functions**: Includes tasks like `resetDUT`, `inputData`, `carryResults`, and functions like `checkResults` to handle test sequences and verification.  
- **Role**: Ensures the **Systolic Array Module** functions as expected across different scenarios, validating its performance and correctness.  

---

## **Design Choices and Limitations**

### **Design Choices**
1. **Systolic Array Architecture**: The project uses a **32x32 systolic array** to balance computational performance and resource utilization. This size was chosen to achieve parallelism without exceeding the FPGA's resource capacity.
2. **Logic Elements (LE) vs. DSP Blocks**: The decision to use **Logic Elements** over **DSP blocks** for multiplication was based on achieving higher operating frequency due to the reduced routing distance in the Cyclone V FPGA.
3. **Fixed-Point Arithmetic**: Fixed-point arithmetic was selected over floating-point to minimize hardware resource usage, thus reducing complexity and power consumption.

### **Limitations**
1. **Scalability**: The current **32x32 systolic array** size limits the scalability of the accelerator for much larger matrix operations, which would require significant resource expansion.
2. **Precision**: The use of **8-bit fixed-point** limits precision, which might not be sufficient for all LLM applications, especially those requiring higher numerical accuracy.
3. **Fixed Clock Frequency**: The design operates at a **fixed 50 MHz clock frequency**, which may limit performance compared to dynamically clocked systems capable of adjusting frequency based on workload demands.

---

## **Design Issues and Optimization**

### **Design Issues**
1. **Routing Congestion**: The usage of **DSP blocks** resulted in lower performance due to routing congestion, especially for larger systolic arrays. This highlighted a need for careful consideration of resource types in FPGA-based designs.
2. **Data Flow Synchronization**: Ensuring proper synchronization between the **Input Buffer**, **Systolic Array**, and **Output Buffer** was challenging, particularly with the need to maintain continuous data flow without stalls.

### **Optimization Strategies**
1. **Routing Optimization**: By switching from **DSP blocks** to **Logic Elements** for the multiplier implementation, routing paths were shortened, significantly boosting the operating frequency of larger systolic arrays.
2. **Pipelining**: Additional pipeline stages were added at critical points to reduce the length of combinational paths, thus improving timing and ensuring the design met the **50 MHz** clock constraint.
3. **Control Signal Synchronization**: The addition of **pipeline registers** for control signals helped align data availability across different modules, reducing the risk of stalls or synchronization issues.

---

## **Timing Constraints and Optimization**  
The project is constrained to a **50 MHz clock frequency** on the Cyclone V FPGA. Timing challenges and solutions include:  
- **Clock Definition**: A 20 ns clock period is defined with a balanced waveform for reliable timing analysis.  
- **Optimizations**:  
  - **Pipeline Registers**: Added to synchronize control signals and reduce critical paths.  
  - **Clock Skew Management**: Adjusted clock uncertainty to ensure signal stability.

---

## **Design Testing**  
Each module was individually tested to verify its functionality. Integrated testing ensured synchronization and correctness of the entire design.  

**Testing Highlights**:  
- Verified accurate matrix multiplication outputs.  
- Ensured proper timing synchronization through pipeline registers and control signal adjustments.

---

## **Implementation Details and Results**  
- **Implementation**: Synthesized on **Altera Cyclone V FPGA** using Intel Quartus Prime.  
- **Results**:  
  - Achieved reliable matrix multiplication operations at 50 MHz.  
  - Efficient resource utilization with no timing violations.  
  - High throughput and accurate results verified through simulation and hardware testing.  
  - **Systolic Array Performance**: The systolic array achieved a **maximum operating frequency of 450 MHz** for a **32x32, 8-bit wide** configuration using **Logic Elements (LE)** for multiplication. In contrast, using **DSP blocks** for the same configuration resulted in a maximum frequency of **155 MHz**. The **Quartus Timing Analyzer** indicated that the longer routing distance required to access DSP blocks led to the slower performance, making it more advantageous to use LEs for certain sizes of systolic arrays where lower latency was essential. However, for smaller configurations, such as **16x16** arrays, both DSP and LE-based implementations achieved similar performance levels, demonstrating that routing distance played a key role in performance differences only at larger scales.

---

## **Future Work and Improvements**  
1. **Enhanced Scalability**: Expand systolic array size to support larger matrix operations.  
2. **Energy Efficiency**: Optimize multipliers for lower power consumption.  
3. **Floating-Point Support**: Add support for higher precision computations.  
4. **Advanced Timing Optimization**: Explore more precise clock constraints to further improve performance.

---  

## **Acknowledgments**  
This project is part of the Fall 2024 coursework and research at Rowan University, inspired by modern LLM architectures. Special thanks to **PI Dwaipayan Chakraborty** for guidance and support throughout the project.
