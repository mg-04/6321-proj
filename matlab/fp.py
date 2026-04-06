# fp.py
# compares bit-accurate fft results agsint floating-point performance
import numpy as np
import os

IN_FILE = 'c/fft_all_tests.in'
OUT_FILE = 'c/fft_all_tests.out'

def bit_reverse(n, bits=10):
    """Reverses the bits of an integer n."""
    res = 0
    for i in range(bits):
        res = (res << 1) | (n & 1)
        n >>= 1
    return res

def hex_to_complex(hex_str, frac_bits=13):
    """
    Helper function to parse the HEX HW output
    Converts 32-bit hex (RRRRIIII) to a complex float in Q3.13
    """
    val = int(hex_str, 16)
    
    r_int = (val >> 16) & 0xFFFF
    i_int = val & 0xFFFF
    
    if r_int >= 0x8000: r_int -= 0x10000
    if i_int >= 0x8000: i_int -= 0x10000
    
    # Convert to float (Divide by 2^frac_bits)
    scale = 2.0**frac_bits
    return complex(r_int / scale, i_int / scale)

def compute_fft_mse(in_file, out_file, n_points=1024):
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
    print(f"Analyzing {num_tests} test cases...")

    for t in range(num_tests):
        start_idx = t * n_points
        end_idx = (t + 1) * n_points
        
        hw_in = np.array([hex_to_complex(h) for h in in_hex[start_idx:end_idx]])
        hw_out_raw = np.array([hex_to_complex(h) for h in out_hex[start_idx:end_idx]])

        # reorder HW output from hardware bit-reversed indices to natural indices
        hw_out_ordered = np.zeros(n_points, dtype=complex)
        for i in range(n_points):
            hw_out_ordered[bit_reverse(i, 10)] = hw_out_raw[i]

        # fp golden model
        # np.fft.fft() * (1/2)^10 due to ALU shifting in my block
        sw_gold = np.fft.fft(hw_in) / n_points

        # calculate MSE for each case
        errors = np.abs(hw_out_ordered - sw_gold)**2
        mse = np.mean(errors)
        all_mse.append(mse)

    avg_mse = np.mean(all_mse)
    # calculate SQNR in dB
    signal_power = np.mean(np.abs(sw_gold)**2)
    sqnr_db = 10 * np.log10(signal_power / avg_mse)

    print("-" * 40)
    print(f"RESULTS FOR {num_tests} TESTS:")
    print(f"Average MSE:  {avg_mse:.4e}")
    print(f"Target SQNR:  > 60.00 dB")
    print(f"Actual SQNR:   {sqnr_db:.2f} dB")
    print("-" * 40)

    if sqnr_db > 60:
        print("STATUS: VERIFIED - Hardware is bit-accurate with expected noise.")
    else:
        print("STATUS: WARNING - SQNR is low. Check for saturation or bit-width bugs.")

if __name__ == "__main__":
    compute_fft_mse(IN_FILE, OUT_FILE)