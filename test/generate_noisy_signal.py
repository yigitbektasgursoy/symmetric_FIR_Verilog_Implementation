import numpy as np
import matplotlib.pyplot as plt

def generate_triangle_wave(t, freq):
    """Generate a triangular wave signal"""
    period = 1.0 / freq
    return 2 * np.abs(2 * (t/period - np.floor(t/period + 0.5))) - 1

def generate_sawtooth_wave(t, freq):
    """Generate a sawtooth wave signal"""
    return 2 * (t * freq - np.floor(0.5 + t * freq))

def generate_pulse_wave(t, freq, duty_cycle=0.3):
    """Generate a pulse wave with specified duty cycle"""
    return np.where((t * freq) % 1.0 < duty_cycle, 1.0, -1.0)

def generate_chirp_signal(t, f0=1, f1=20):
    """Generate a chirp signal (frequency sweep)"""
    return np.sin(2 * np.pi * (f0 * t + ((f1-f0)/2) * t**2))

def get_filter_coefficients():
    """
    Returns the FIR filter coefficients.
    These coefficients represent a low-pass filter.
    """
    coefficients = np.array([2, 14, 7, 28, 15, 32])
    coefficients = coefficients / np.sum(coefficients)
    return coefficients

def apply_filter(signal, coefficients):
    """
    Applies FIR filtering using the given coefficients.
    """
    return np.convolve(signal, coefficients, mode='same')

def generate_noisy_signal(num_samples=1000, freq=10, noise_amplitude=0.2, signal_type='sine'):
    # Time vector
    t = np.linspace(0, 1, num_samples)
    
    # Generate base signal (normalized between -1 and 1)
    if signal_type.lower() == 'sine':
        clean_signal = np.sin(2 * np.pi * freq * t)
    elif signal_type.lower() == 'square':
        clean_signal = np.sign(np.sin(2 * np.pi * freq * t))
    elif signal_type.lower() == 'cos':
        clean_signal = np.cos(2 * np.pi * freq * t)
    elif signal_type.lower() == 'triangle':
        clean_signal = generate_triangle_wave(t, freq)
    elif signal_type.lower() == 'sawtooth':
        clean_signal = generate_sawtooth_wave(t, freq)
    elif signal_type.lower() == 'pulse':
        clean_signal = generate_pulse_wave(t, freq)
    elif signal_type.lower() == 'chirp':
        clean_signal = generate_chirp_signal(t)
    else:
        raise ValueError("Unsupported signal type. Choose 'sine', 'square', 'cos', 'triangle', 'sawtooth', 'pulse', or 'chirp'")
    
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
            if value < 0:
                value = (1 << 12) + value
            hex_value = format(value & 0xFFF, '03x')
            f.write(f"{hex_value}\n")

def get_user_input():
    print("\nConfigure test signal parameters:")
    print("---------------------------------")
    
    # Get sample rate
    sample_rate = int(input("Sample rate (Hz) [default=1000]: ") or 1000)
    
    # Get signal frequency
    signal_freq = float(input("Signal frequency (Hz) [default=10]: ") or 10)
    
    # Get noise amplitude
    noise_amplitude = float(input("Noise amplitude (0.0-1.0) [default=0.2]: ") or 0.2)
    
    # Get number of samples
    num_samples = int(input("Number of samples [default=1000]: ") or 1000)
    
    # Get signal type
    print("\nAvailable signal types: 'sine', 'square', 'cos', 'triangle', 'sawtooth', 'pulse', 'chirp'")
    signal_type = input("Signal type [default=sine]: ").lower() or 'sine'
    
    return sample_rate, signal_freq, noise_amplitude, num_samples, signal_type

def main():
    # Get configuration from user
    sample_rate, signal_freq, noise_amplitude, num_samples, signal_type = get_user_input()
    
    print("\nGenerating signal with parameters:")
    print(f"Sample rate: {sample_rate} Hz")
    print(f"Signal frequency: {signal_freq} Hz")
    print(f"Noise amplitude: {noise_amplitude}")
    print(f"Number of samples: {num_samples}")
    print(f"Signal type: {signal_type}")
    
    # Generate signals
    noisy_signal, clean_signal, time = generate_noisy_signal(
        num_samples=num_samples,
        freq=signal_freq,
        noise_amplitude=noise_amplitude,
        signal_type=signal_type
    )

    # Get and apply filter
    coefficients = get_filter_coefficients()
    filtered_signal = apply_filter(noisy_signal, coefficients)

    # Save both signals to files
    save_to_hex_file(noisy_signal, 'input_signal.txt')
    save_to_hex_file(filtered_signal.astype(np.int16), 'filtered_signal.txt')

    # Plot all signals
    plt.figure(figsize=(12, 8))
    
    plt.subplot(3, 1, 1)
    plt.plot(time, clean_signal, label=f'Clean {signal_type} Signal')
    plt.title(f'Clean {signal_type} Signal')
    plt.grid(True)
    plt.legend()
    
    plt.subplot(3, 1, 2)
    plt.plot(time, noisy_signal/2000, label=f'Noisy {signal_type} Signal', alpha=0.7)
    plt.title(f'Noisy {signal_type} Signal')
    plt.grid(True)
    plt.legend()
    
    plt.subplot(3, 1, 3)
    plt.plot(time, filtered_signal/2000, label=f'Filtered {signal_type} Signal', alpha=0.7)
    plt.title(f'Filtered {signal_type} Signal')
    plt.grid(True)
    plt.legend()
    
    plt.tight_layout()
    plt.show()

    # Print first few values for verification
    print("\nFirst 10 values in decimal and hexadecimal:")
    print("\nNoisy Signal:")
    for i in range(10):
        print(f"Decimal: {noisy_signal[i]:5d}, Hex: {format(noisy_signal[i] & 0xFFF, '03x')}")
    
    print("\nFiltered Signal:")
    for i in range(10):
        filtered_val = int(filtered_signal[i])
        print(f"Decimal: {filtered_val:5d}, Hex: {format(filtered_val & 0xFFF, '03x')}")

if __name__ == "__main__":
    main()
