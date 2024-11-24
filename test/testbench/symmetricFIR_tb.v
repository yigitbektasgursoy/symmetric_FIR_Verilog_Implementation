`timescale 1ns / 1ps

// Testbench for symmetricFIR module
// This testbench reads coefficients and input data from files and verifies the FIR filter operation
module symmetricFIR_tb();
    // Design Parameters
    // These must match the parameters in the DUT (Device Under Test)
    parameter COEFF_NUM = 6,          // Number of filter taps
              COEFF_WIDTH = 8,        // Coefficient precision
              DATA_DELAY = 12,        // Delay line length (2x COEFF_NUM)
              DATA_WIDTH = 12,        // Input data precision
              
              // Calculated widths for maintaining precision through pipeline stages
              STAGE1_WIDTH = DATA_WIDTH + 1,    // After symmetric pair addition
              STAGE2_WIDTH = STAGE1_WIDTH + COEFF_WIDTH + 1,  // After multiplication
              STAGE3_WIDTH = STAGE2_WIDTH + 1,  // After adding multiplication results
              OUTPUT_WIDTH = STAGE3_WIDTH + 2;  // Final output width

    // Testbench Signals
    reg clk;                          // System clock
    reg clr;                          // Synchronous reset
    reg load;                         // Coefficient load enable
    reg signed [COEFF_WIDTH-1:0] coeff_value; // Input coefficient
    reg signed [DATA_WIDTH-1:0] noisy_signal; // Input signal
    wire signed [OUTPUT_WIDTH - 1:0] filtered_signal;       // Filter output
    reg filtering_process_done;               // Test completion flag

    // Instantiate the Device Under Test (DUT)
    // Connect testbench signals to the FIR filter module
    symmetricFIR #(
        .COEFF_NUM(COEFF_NUM),
        .COEFF_WIDTH(COEFF_WIDTH),
        .DATA_DELAY(DATA_DELAY),
        .DATA_WIDTH(DATA_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) DUT (
        .clk(clk),
        .clr(clr),
        .load(load),
        .coeff_value(coeff_value),
        .noisy_signal(noisy_signal),
        .filtered_signal(filtered_signal)
    );

    // Clock Generation Parameters
    integer CLK_PERIOD = 10;          // Clock period (10ns = 100MHz)
    integer fd_input, fd_coeff;       // File handles for test vectors

    // Clock Generation Block
    // Generates a continuous clock signal
    initial begin
        clk = 0;                      // Initialize clock
        forever #(CLK_PERIOD/2) clk = ~clk; // Toggle every half period
    end

    // DUT Initialization Task
    // Resets the DUT to a known state
    task init_dut();
        begin
            filtering_process_done = 0; // Clear completion flag
            clr = 1;                    // Assert reset
            load = 0;                   // Disable coefficient loading
            coeff_value = 0;            // Clear coefficient input
            noisy_signal = 0;           // Clear signal input
            @(negedge clk);             // Wait for clock
            clr = 0;                    // Release reset
        end
    endtask

    // Coefficient Loading Task
    // Reads filter coefficients from a file and loads them into the DUT
    task load_coeffs();
        begin
            load = 1;                 // Enable coefficient loading
            // Open coefficient file
            fd_input = $fopen("coeff_val.txt", "r");

            // Check for file open error
            if (fd_input == 0) begin
                $display("ERROR: Unable to open signal file: coeff_val.txt");
            end 
            else begin
                // Read and load each coefficient
                while (!$feof(fd_input)) begin
                    $fscanf(fd_input, " %d", coeff_value); // Read decimal value
                    @(negedge clk);       // Wait for clock
                end
            end
            $fclose(fd_input);           // Close file
            load = 0;                    // Disable loading
        end
    endtask

    // Input Signal Loading Task
    // Reads input signal samples from a file and feeds them to the DUT
    task load_data();
        begin
            // Open input signal file
            fd_coeff = $fopen("input_signal.txt", "r");

            // Check for file open error
            if (fd_coeff == 0) begin
                $display("ERROR: Unable to open signal file: coeff_val.txt");
            end 
            else begin
                // Read and load each input sample
                while (!$feof(fd_coeff)) begin
                    $fscanf(fd_coeff, " %h", noisy_signal); // Read hex value
                    @(negedge clk);       // Wait for clock
                end
            end
            $fclose(fd_coeff);        // Close file
            filtering_process_done = 1; // Set completion flag
        end
    endtask

    // Main Testbench Flow
    initial begin
        init_dut();                   // Reset DUT
        load_coeffs();                // Load filter coefficients
        load_data();                  // Process input signal
        wait(filtering_process_done); // Wait for completion
        $finish(2);                   // End simulation
    end
endmodule