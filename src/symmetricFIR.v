module symmetricFIR #(
    // Design Parameters
    parameter COEFF_NUM = 6,     // Number of filter coefficients (taps)
    parameter COEFF_WIDTH = 8,   // Width of each coefficient
    parameter DATA_DELAY = 12,   // Length of delay line (2x COEFF_NUM for symmetric filter)
    parameter DATA_WIDTH = 12,   // Width of input data
    
    // Calculated widths for each processing stage to prevent overflow
    parameter STAGE1_WIDTH = DATA_WIDTH + 1,    // Width after symmetric pair addition
    parameter STAGE2_WIDTH = STAGE1_WIDTH + COEFF_WIDTH + 1,  // Width after coefficient multiplication
    parameter STAGE3_WIDTH = STAGE2_WIDTH + 1,  // Width after adding multiplication results
    parameter OUTPUT_WIDTH = STAGE3_WIDTH + 2    // Final output width after accumulation
)(
    // Interface Ports
    input clk,                                    // System clock
    input clr,                                    // Synchronous clear
    input load,                                   // Coefficient load enable
    input signed [COEFF_WIDTH-1:0] coeff_value,   // Input coefficient value
    input signed [OUTPUT_WIDTH-1:0] noisy_signal, // Input signal to be filtered
    output reg signed [30:0] filtered_signal      // Filtered output signal
);

    // Register declarations for coefficient handling
    reg signed [COEFF_WIDTH-1:0] coeff_reg [0:COEFF_NUM-1];    // Store filter coefficients
    reg [$clog2(COEFF_NUM) - 1:0] coeff_array_index;          // Index for coefficient loading
    reg coeff_loaded;                                          // Flag: coefficients loaded completely

    // Data pipeline registers
    reg signed[DATA_WIDTH-1:0] data_reg [0:DATA_DELAY-1];     // Delay line for input samples
    reg data_loaded;                                          // Flag: delay line is filled
    reg data_ready;                                          // Flag: processing can begin
    reg [1:0]data_ready_counter;                            // Counter for processing stages
    reg [$clog2(DATA_DELAY) - 1:0] data_loaded_counter;    // Counter for delay line filling

    // Pipeline stage registers
    // Stage 1: Symmetric pair addition results
    reg signed [STAGE1_WIDTH-1:0] stage1_add_reg [0:DATA_DELAY/2-1];
    // Stage 2: Multiplication results
    reg signed [STAGE2_WIDTH-1:0] stage2_mul_reg [0:DATA_DELAY/2-1];
    // Stage 3: Final addition results
    reg signed [STAGE3_WIDTH-1:0] stage3_add_reg [0:DATA_DELAY/4-1];

    // Data loading control block
    // Manages the filling of the delay line
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            data_loaded_counter <= 0;
            data_loaded <= 0;
        end
        else begin
            // Set data_loaded flag when delay line is full
            if(data_loaded_counter == DATA_DELAY) begin
                data_loaded <= 1;
            end
            else begin
                data_loaded_counter <= data_loaded_counter + 1;
                data_loaded <= 0;
            end
        end
    end

    // Input data shift register - first stage
    // Loads new input samples into the delay line
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            data_reg[0] <= 0;
        end
        else if (coeff_loaded) begin
            data_reg[0] <= noisy_signal;  // Load new sample
        end
    end

    // Generate block for delay line shift register
    // Creates the tapped delay line structure
    genvar i;
    generate
        for (i = 1; i < DATA_DELAY; i = i + 1) begin : shift_reg
            always @(posedge clk or posedge clr) begin
                if (clr) begin
                    data_reg[i] <= 0;
                end
                else if (coeff_loaded) begin
                    data_reg[i] <= data_reg[i-1];  // Shift data through
                end
            end
        end
    endgenerate

    // Coefficient loading logic
    // Manages the loading of filter coefficients
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            coeff_array_index <= 0;
            coeff_loaded <= 0;
        end
        else begin
            if(load) begin
                if(coeff_array_index == COEFF_NUM) begin
                    coeff_loaded <= 1;  // All coefficients loaded
                end
                else begin
                    coeff_array_index <= coeff_array_index + 1;
                    coeff_reg[coeff_array_index] <= coeff_value;
                    coeff_loaded <= 0;
                end
            end
        end
    end

    // Processing stage control logic
    // Manages the timing of the three processing stages
    always @(posedge clk or posedge clr) begin
        if (clr) begin
            data_ready <= 0;
            data_ready_counter <= 0;
        end
        else begin
            if(data_loaded) begin      
                if(data_ready_counter == 3) begin  // All three stages complete
                    data_ready <= 1;
                end
                else begin
                    data_ready_counter <= data_ready_counter + 1;
                end
            end
        end
    end

    // Main processing pipeline generate block
    // Implements the three stages of symmetric FIR filtering:
    // 1. Add symmetric pairs
    // 2. Multiply by coefficients
    // 3. Add multiplication results
    genvar j;
    generate
        for( j = 0; j < COEFF_NUM; j = j + 1) begin
            always @(posedge clk or posedge clr) begin
                if(clr) begin
                    filtered_signal <= 0;
                end
                else begin
                    if(data_loaded) begin
                        // Stage 1: Add symmetric tap pairs
                        stage1_add_reg[j] <= data_reg[j] + data_reg[(DATA_DELAY-1) - j];
                        // Stage 2: Multiply by coefficients
                        stage2_mul_reg[j] <= stage1_add_reg[j] * coeff_reg[j];
                        // Stage 3: Add multiplication results (only for first half due to symmetry)
                        if(COEFF_NUM/2 > j) begin
                             stage3_add_reg[j] <= stage2_mul_reg[j] + stage2_mul_reg[(COEFF_NUM - 1) - j];
                        end
                    end
                    // Final accumulation of results
                    if(data_ready) begin
                        if(COEFF_NUM/2 > j) begin
                            filtered_signal <= filtered_signal + stage3_add_reg[j];
                        end
                    end
                end
            end
        end
    endgenerate

endmodule