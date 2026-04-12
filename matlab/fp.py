# fp.py
# compares bit-accurate fft results agsint floating-point performance
import numpy as np
import os
import matplotlib.pyplot as plt  # New import

IN_FILE = "FFT_input/input_q1_15_v3.hex"
OUT_FILE = "FFT_input/output_q1_15.hex"

def bit_reverse(n, bits=10):
    """Reverses the bits of an integer n."""
    res = 0
    for i in range(bits):
        res = (res << 1) | (n & 1)
        n >>= 1
    return res

def hex_to_real(hex_str, frac_bits=15):
    """
    Helper function to parse the HEX HW input
    Converts 16-bit hex (RRRR) to a complex float in Q1.15
    """
    val = int(hex_str, 16)
    
    r_int = val
    i_int = 0
    
    if r_int >= 0x8000: r_int -= 0x10000
    if i_int >= 0x8000: i_int -= 0x10000
    
    # Convert to float (Divide by 2^frac_bits)
    scale = 2.0**frac_bits
    return complex(r_int / scale, i_int / scale)

def hex_to_complex(hex_str, frac_bits=15):
    """
    Helper function to parse the HEX HW output
    Converts 32-bit hex (RRRRIIII) to a complex float in Q1.15
    """
    val = int(hex_str, 16)
    
    r_int = (val >> 16) & 0xFFFF
    i_int = val & 0xFFFF
    
    if r_int >= 0x8000: r_int -= 0x10000
    if i_int >= 0x8000: i_int -= 0x10000
    
    # Convert to float (Divide by 2^frac_bits)
    scale = 2.0**frac_bits
    return complex(r_int / scale, i_int / scale)

def compute_fft_metrics(in_file, out_file, n_points=1024):
    if not os.path.exists(in_file) or not os.path.exists(out_file):
        print(f"ERROR: Files not found. Check paths: {in_file}, {out_file}")
        return

    with open(in_file, 'r') as f:
        in_hex = [line.strip() for line in f if line.strip()]
    with open(out_file, 'r') as f:
        out_hex = [line.strip() for line in f if line.strip()]

    num_tests = len(in_hex) // n_points
    if num_tests == 0:
        print("ERROR: Input file is empty or shorter than 1024 lines.")
        return

    all_mse = []
    all_nrmse = []
    
    print(f"Analyzing {num_tests} test cases...")

    for t in range(num_tests):
        start_idx = t * n_points
        end_idx = (t + 1) * n_points
        
        hw_in = np.array([hex_to_real(h) for h in in_hex[start_idx:end_idx]])
        hw_out_raw = np.array([hex_to_complex(h) for h in out_hex[start_idx:end_idx]])

        hw_out_ordered = np.zeros(n_points, dtype=complex)
        for i in range(n_points):
            hw_out_ordered[bit_reverse(i, 10)] = hw_out_raw[i]

        # golden model (normalized by 2^8 to match Q9.7)
        sw_gold = np.fft.fft(hw_in) / (2 ** 8)

        # NRMSE calculations
        sq_error = np.abs(hw_out_ordered - sw_gold)**2
        mse = np.mean(sq_error)
        rmse = np.sqrt(mse)
        # normalization
        y_max = np.max(np.abs(sw_gold))
        y_min = np.min(np.abs(sw_gold))
        y_range = y_max - y_min
        
        # Avoid division by zero for DC inputs
        if y_range == 0: y_range = 1e-9 
        
        nrmse = rmse / y_range
        
        all_mse.append(mse)
        all_nrmse.append(nrmse)

        # Q9.7 Overflow Check
        max_q9_7, min_q9_7 = 255.992, -256.0
        if np.any(np.abs(sw_gold.real) > 256) or np.any(np.abs(sw_gold.imag) > 256):
            print(f"  [!] TEST {t}: GOLDEN MODEL OVERFLOW DETECTED")

    avg_mse = np.mean(all_mse)
    avg_nrmse = np.mean(all_nrmse) * 100
    worst_nrmse = np.max(all_nrmse) * 100
    
    signal_power = np.mean(np.abs(sw_gold)**2)
    sqnr_db = 10 * np.log10(signal_power / avg_mse)

    print("-" * 45)
    print(f"RESULTS FOR {num_tests} TESTS:")
    print(f"Average SQNR:  {sqnr_db:.2f} dB (Target > 60dB)")
    print(f"Average NRMSE: {avg_nrmse:.4f} %")
    print(f"Worst  NRMSE: {worst_nrmse:.4f} %")
    print("-" * 45)

    if sqnr_db > 60:
        print("STATUS: SUCCESS - Accuracy requirements met.")
    else:
        print("STATUS: WARNING - Precision issues detected.")

def plot_overlay_fft(in_file, n_points=1024, num_to_plot=10):
    if not os.path.exists(in_file):
        print(f"ERROR: File not found: {in_file}")
        return

    with open(in_file, 'r') as f:
        in_hex = [line.strip() for line in f if line.strip()]

    num_tests = len(in_hex) // n_points
    plot_limit = min(num_to_plot, num_tests)

    # Initialize a single plot
    plt.figure(figsize=(12, 7))
    
    # Use a colormap to get 10 distinct colors
    colors = plt.cm.viridis(np.linspace(0, 1, plot_limit))

    print(f"Plotting overlay for {plot_limit} test cases...")

    for t in range(plot_limit):
        start_idx = t * n_points
        end_idx = (t + 1) * n_points
        
        # Convert hex to complex float
        hw_in = np.array([hex_to_real(h) for h in in_hex[start_idx:end_idx]])

        # Compute Golden FFT and normalize by 2^8 per your hardware scaling
        sw_gold = np.fft.fft(hw_in) / (2 ** 8)

        # Convert Magnitude to dB
        mag_db = 20 * np.log10(np.abs(sw_gold) + 1e-12)
        
        # Overlay on the same plot
        plt.plot(mag_db, color=colors[t], alpha=0.7, label=f"Test Case {t}")

    # Formatting the single plot
    plt.title(f"Overlay of {plot_limit} FFT Golden Model Magnitude Responses", fontsize=14)
    plt.xlabel("Frequency Bin (k)", fontsize=12)
    plt.ylabel("Magnitude (dB)", fontsize=12)
    plt.grid(True, which='both', linestyle='--', alpha=0.4)
    plt.legend(loc='upper right', bbox_to_anchor=(1.15, 1)) # Move legend outside to see plot
    
    # Set y-axis limits to show the 60dB floor clearly
    # Adjust -80 to -100 depending on your specific input noise
    plt.ylim(bottom=-80) 

    plt.tight_layout()
    plt.savefig("fft_overlay_results.png", dpi=300)
    print("Overlay plot saved as 'fft_overlay_results.png'")
    plt.show()

def plot_hw_fft(out_file, n_points=1024, num_to_plot=10):
    """
    Parses the hardware output HEX file, reorders bit-reversed indices, 
    and plots the magnitude spectrum.
    """
    if not os.path.exists(out_file):
        print(f"ERROR: File not found: {out_file}")
        return

    with open(out_file, 'r') as f:
        out_hex = [line.strip() for line in f if line.strip()]

    num_tests = len(out_hex) // n_points
    plot_limit = min(num_to_plot, num_tests)

    plt.figure(figsize=(12, 7))
    # Using a different colormap (magma) to distinguish from the Golden plot
    colors = plt.cm.magma(np.linspace(0.2, 0.9, plot_limit))

    print(f"Plotting Hardware overlay for {plot_limit} test cases...")

    for t in range(plot_limit):
        start_idx = t * n_points
        end_idx = (t + 1) * n_points
        
        # 1. Parse Hex (RRRRIIII) to complex floats
        hw_out_raw = np.array([hex_to_complex(h) for h in out_hex[start_idx:end_idx]])

        # 2. Reorder from Bit-Reversed order to Natural Frequency order
        hw_out_ordered = np.zeros(n_points, dtype=complex)
        for i in range(n_points):
            hw_out_ordered[bit_reverse(i, 10)] = hw_out_raw[i]

        # 3. Convert Magnitude to dB
        mag_db = 20 * np.log10(np.abs(hw_out_ordered) + 1e-12)
        
        plt.plot(mag_db, color=colors[t], alpha=0.7, label=f"HW Case {t}")

    plt.title(f"Overlay of {plot_limit} Hardware FFT Magnitude Responses", fontsize=14)
    plt.xlabel("Frequency Bin (k)", fontsize=12)
    plt.ylabel("Magnitude (dB)", fontsize=12)
    plt.grid(True, which='both', linestyle='--', alpha=0.4)
    plt.legend(loc='upper right', bbox_to_anchor=(1.15, 1))
    plt.ylim([-90, 5]) # Matches the Golden Model scale for easy comparison

    plt.tight_layout()
    plt.savefig("fft_hardware_overlay.png", dpi=300)
    print("Hardware plot saved as 'fft_hardware_overlay.png'")
    plt.show()

if __name__ == "__main__":
    compute_fft_metrics(IN_FILE, OUT_FILE)
    plot_overlay_fft(IN_FILE)
    plot_hw_fft(OUT_FILE)