import numpy as np

def quantize(x, word_length=16, frac_length=15):
    """Clamps and rounds to fixed-point integer representation."""
    scale = 2**frac_length
    xq = np.round(x * scale)
    min_val = -2**(word_length - 1)
    max_val = 2**(word_length - 1) - 1
    return np.clip(xq, min_val, max_val)

def fxp_mult(a, b, frac_length=15):
    """Fixed-point multiplication: (a * b) >> frac_length"""
    res = (a * b) // (2**frac_length)
    return quantize(res / (2**frac_length), 16, frac_length)

def bit_reverse(x):
    N = len(x)
    j = 0
    for i in range(1, N):
        bit = N >> 1
        while j & bit:	# if current bit = 1
            j ^= bit
            bit >>= 1
        j ^= bit
        if i < j:
            x[i], x[j] = x[j], x[i]
    return x

def fft_1024_fixed(xr, xi, twiddle_r, twiddle_i, N=1024, word_length=16, frac_length=13):
	# the maximum value of the butterfly can go to 1 + sqrt(2) = 2.414, 
	# so need 2 additional bits for Q, use 3.13
    # Inputs xr, xi are assumed to be already quantized 16-bit integers.
    stages = int(np.log2(N))
    
    xr = bit_reverse(xr.copy())
    xi = bit_reverse(xi.copy())
    
    # 2. FFT Stages
    for stage in range(1, stages + 1):
        m = 2**stage
        m2 = m // 2

        for j in range(0, m2):
            tw_idx = j * (N // m)
            wr = twiddle_r[tw_idx]
            wi = twiddle_i[tw_idx]
            
            for k in range(j, N, m):
                # Fixed-point Butterfly
                # t_real = (xr[k+m2]*wr - xi[k+m2]*wi) >> frac_length
                tr = (xr[k+m2] * wr - xi[k+m2] * wi) // (2**frac_length)
                ti = (xr[k+m2] * wi + xi[k+m2] * wr) // (2**frac_length)
                
                # Update with scaling (divide by 2) to prevent overflow
                xr[k+m2] = (xr[k] - tr) // 2
                xi[k+m2] = (xi[k] - ti) // 2
                xr[k] = (xr[k] + tr) // 2
                xi[k] = (xi[k] + ti) // 2
    return xr, xi

N = 1024
word_length = 16
frac_length = 13  # Corresponds to Q3.13 format

k = np.arange(N // 2) # Indices 0 to 511 for W_1024^k
theta = -2 * np.pi * k / N
twiddle_r = quantize(np.cos(theta), word_length, frac_length)
twiddle_i = quantize(np.sin(theta), word_length, frac_length)

# Generate weights file for Verilog simulation if it doesn't exist
try:
    np.loadtxt('weights.in', dtype=int)
    print("weights.in already exists.")
except (FileNotFoundError, IOError):
    print("weights.in not found. Generating weights file.")
    np.savetxt('weights.in', np.column_stack((twiddle_r, twiddle_i)), fmt='%d')
    print("Saved generated weights to weights.in")

try:
    input_data = np.loadtxt('fft.in', dtype=int)
    xr_in = input_data[:, 0]
    xi_in = input_data[:, 1]
    print("Read input from fft.in")
    test_signal = None  # No float signal available for MSE comparison
except (FileNotFoundError, IOError):
    print("fft.in not found. Generating a test signal and creating fft.in.")
    t = np.linspace(0, 1, N, endpoint=False)

    # Input signal: sum of two sines
    test_signal = 0.5 * np.sin(2 * np.pi * 50 * t) + 0.2 * np.sin(2 * np.pi * 120 * t)
    
    # quantize and safe to fft.in
    xr_in = quantize(test_signal, word_length, frac_length)
    xi_in = quantize(np.zeros(N), word_length, frac_length)
    np.savetxt('fft.in', np.column_stack((xr_in, xi_in)), fmt='%d')
    print("Saved generated input to fft.in")

# Compute the FFT using the fixed-point implementation
res_r, res_i = fft_1024_fixed(xr_in, xi_in, twiddle_r, twiddle_i, N=N, word_length=word_length, frac_length=frac_length)

# save the result to fft.out in (re, im) pairs
np.savetxt('fft.out', np.column_stack((res_r, res_i)), fmt='%d')
print("FFT result written to fft.out")

# --- Analysis ---
scale = 2**frac_length
if test_signal is not None:
    expected = np.fft.fft(test_signal) / N
    res_fixed_complex = (res_r + 1j * res_i) / scale
    res_float_complex = expected
    errors = np.abs(res_fixed_complex - res_float_complex)**2
    mse = np.mean(errors)
    print(f"MSE (vs float FFT): {mse}")

# simple script to find the maximum values
mag = np.sqrt(res_r**2 + res_i**2)
top_indices = np.argsort(mag)[-10:][::-1]

print(f"{'Rank':<5} | {'Index (Hz)':<10} | {'Raw Mag':<10} | {'Scaled Mag':<12}")
print("-" * 45)

count = 1
seen_freqs = set()

# print top 5 freqs
for idx in top_indices:
    # FFT is symmetric; index k and N-k are the same frequency
    freq = idx if idx <= 512 else 1024 - idx
    if freq not in seen_freqs and count <= 5:
        raw_val = mag[idx]
        scaled_val = raw_val / scale
        
        print(f"{count:<5} | {idx:<10} | {raw_val:<10.1f} | {scaled_val:<12.4f}")
        
        seen_freqs.add(freq)
        count += 1

print("\nFor the generated test signal, expected peaks are at 50 Hz and 120 Hz.")
