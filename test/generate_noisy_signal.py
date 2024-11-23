import numpy as np
import matplotlib.pyplot as plt

def generate_noisy_signal(num_samples=1000, freq=10, noise_amplitude=0.2, signal_type='sin'):
    # Time vector
    t = np.linspace(0, 1, num_samples)
    
    # Generate base signal (normalized between -1 and 1)
    if signal_type.lower() == 'sin':
        clean_signal = np.sin(2 * np.pi * freq * t)
    else:  # cos
        clean_signal = np.cos(2 * np.pi * freq * t)
    
    # Generate noise
    noise = np.random.normal(0, noise_amplitude, num_samples)
    
    # Combine signal and noise
    noisy_signal = clean_signal + noise
    
    # Scale to fit in 12-bit signed range (-2048 to 2047)
    scaling_factor = 2000  # Leaving some margin for noise
    scaled_signal = (noisy_signal * scaling_factor).astype(np.int16)
    
    # Clip to ensure values stay within 12-bit signed range
    scaled_signal = np.clip(scaled_signal, -2048, 2047)
    
    return scaled_signal, clean_signal, t

def save_to_hex_file(signal, filename):
    with open(filename, 'w') as f:
        for value in signal:
            # Convert to 12-bit hex, handling negative numbers
            if value < 0:
                # Convert negative number to two's complement
                value = (1 << 12) + value
            hex_value = format(value & 0xFFF, '03x')  # 12-bit hex value
            f.write(f"{hex_value}\n")

def plot_signals(original, noisy, t):
    plt.figure(figsize=(12, 6))
    
    plt.subplot(2, 1, 1)
    plt.plot(t, original, label='Clean Signal')
    plt.title('Clean Signal')
    plt.grid(True)
    plt.legend()
    
    plt.subplot(2, 1, 2)
    plt.plot(t, noisy, label='Noisy Signal', alpha=0.7)
    plt.title('Noisy Signal')
    plt.grid(True)
    plt.legend()
    
    plt.tight_layout()
    plt.show()

# Generate signals
num_samples = 1000
frequency = 5  # 5 Hz signal
noise_level = 0.2  # Adjust noise level (0.0 to 1.0)
signal_type = 'sin'  # or 'cos'

noisy_signal, clean_signal, time = generate_noisy_signal(
    num_samples=num_samples,
    freq=frequency,
    noise_amplitude=noise_level,
    signal_type=signal_type
)

# Save to file
save_to_hex_file(noisy_signal, 'input_signal.txt')

# Plot the signals
plot_signals(clean_signal, noisy_signal/2000, time)  # Divide by scaling factor for visualization

# Print first few values for verification
print("\nFirst 10 values in decimal and hexadecimal:")
for i in range(10):
    print(f"Decimal: {noisy_signal[i]:5d}, Hex: {format(noisy_signal[i] & 0xFFF, '03x')}")
