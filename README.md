# Symmetric FIR Filter Implementation in Verilog

A highly configurable, pipelined Symmetric FIR (Finite Impulse Response) filter implementation in Verilog HDL. This design leverages symmetry to optimize hardware resources while maintaining high throughput through pipelining.

## Architecture Overview

![Block Diagram](docs/symmetricFIR_block_diagram.jpeg)

The filter implements a three-stage pipelined architecture:
1. **Symmetric Pair Addition** - Adds symmetric tap pairs to reduce multiplications
2. **Coefficient Multiplication** - Multiplies summed pairs with filter coefficients
3. **Result Accumulation** - Combines multiplication results for final output

### Key Features

- **Configurable Parameters**
  - Adjustable number of filter taps
  - Configurable data and coefficient widths
  - Automatic bit-width management to prevent overflow
- **Resource Optimization**
  - Exploits coefficient symmetry to reduce multiplications by 50%
  - Pipelined architecture for improved throughput
- **Robust Design**
  - Synchronous reset capability
  - Dynamic coefficient loading
  - Built-in overflow protection

### Directory Structure

```
symmetric_FIR_Verilog_Implementation/
├── src/
│   └── symmetricFIR.v       # Main implementation
├── test/
│   ├── testbench/
│   │   └── symmetricFIR_tb.v
│   ├── generate_noisy_signal.py
│   ├── input_signal.txt
│   └── coeff_val.txt
└── docs/
    ├── behav_sim_example_1.jpeg
    ├── behav_sim_example_2.jpeg
    └── symmetricFIR_block_diagram.jpeg
```

## Test Signal Generation

The project includes a configurable Python script (`generate_noisy_signal.py`) for test signal generation:

### Configurable Parameters
- Sample rate (Hz)
- Signal frequency (Hz)
- Noise amplitude
- Number of samples
- Signal type (sine, square, etc.)

Example configuration:
```python
# Configure test signal parameters
sample_rate = 1000    # Hz
signal_freq = 10      # Hz
noise_amplitude = 0.1
num_samples = 1000
signal_type = 'sine'  # Options: 'sine', 'square'
```

The script automatically generates `input_signal.txt` for testing purposes.

## Simulation Results

![Simulation Example 1](docs/behav_sim_example_1.jpeg)
![Simulation Example 2](docs/behav_sim_example_2.jpeg)

## Testing

The testbench provides comprehensive verification:
- Automated coefficient loading from file
- Input signal processing from external source
- Waveform verification capabilities
- Built-in completion detection

### Running Tests in Vivado

1. Create New Project in Vivado
2. Add Design Sources:
   - Add `symmetricFIR.v` as design source
   - Add `symmetricFIR_tb.v` as simulation source

3. Add Test Vector Files:
   - Right-click on Simulation Sources → Add Sources
   - Select "Add or create simulation sources"
   - **Important**: Choose "All Files (*.*)" in file type dropdown
   - Add both `coeff_val.txt` and `input_signal.txt`
   > Note: .txt files will only be visible when "All Files (*.*)" is selected

4. Configure Waveform Settings:
   - Start simulation and open waveform window
   - For input signal (`noisy_signal`):
     * Right-click → Waveform Style → Analog
     * Right-click → Radix → Signed Decimal
   - For output signal (`filtered_signal`):
     * Right-click → Waveform Style → Analog
     * Right-click → Radix → Signed Decimal
   > Note: Analog display style allows better visualization of the filtering effect

5. Run Simulation:
   - Start Behavioral Simulation
   - Monitor filtered output and verification results

### Waveform Display Example
![Simulation Example 1](docs/behav_sim_example_1.jpeg)
- Input (top): Noisy signal in analog format
- Output (bottom): Filtered signal showing noise reduction

## License

MIT License

## Author

Yiğit Bektaş Gürsoy

## Contact

- Email: yigitbektasgursoy@gmail.com