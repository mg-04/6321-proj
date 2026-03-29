import numpy as np

def quantize(x, word_length=16, frac_length=13):
    scale = 2**frac_length
    xq = np.round(x * scale)
    min_val = -2**(word_length - 1)
    max_val = 2**(word_length - 1) - 1
    return np.clip(xq, min_val, max_val).astype(np.int32)

def bit_reverse_val(i, n_bits=10):
    """Reverses the bits of an integer."""
    return int('{:0{b}b}'.format(i, b=n_bits)[::-1], 2)

def fft_1024_fixed_dif(xr, xi, twiddle_r, twiddle_i, N=1024, frac_length=13):
    """DIF FFT: Matches Verilog Controller and DIF ALU Scaling."""
    xr = xr.copy().astype(np.int64)
    xi = xi.copy().astype(np.int64)
    stages = int(np.log2(N))
    
    # 1. DIF FFT Stages
    for stage in range(stages):
        stride = 512 >> stage
        num_groups = 1 << stage
        
        for g in range(num_groups):
            group_start = g * (2 * stride)
            
            for i in range(stride):
                idx_a = group_start + i
                idx_b = group_start + i + stride
                
                # Twiddle index matches: w_addr = i << stage_cnt
                tw_idx = i << stage
                wr = twiddle_r[tw_idx]
                wi = twiddle_i[tw_idx]
                
                # --- DIF Butterfly Math (Matches your ALU) ---
                # A' = (A + B) / 2
                # B' = ((A - B) * W) / 2
                
                # Temporaries for A + B and A - B
                sum_r, sum_i = xr[idx_a] + xr[idx_b], xi[idx_a] + xi[idx_b]
                diff_r, diff_i = xr[idx_a] - xr[idx_b], xi[idx_a] - xi[idx_b]
                
                # Update A (Scaled by 2)
                xr[idx_a] = sum_r >> 1
                xi[idx_a] = sum_i >> 1
                
                # Update B (Complex Mult then Scaled by 2)
                # Total shift = 13 (Q format) + 1 (FFT scaling) = 14
                tr = (diff_r * wr - diff_i * wi) >> (frac_length + 1)
                ti = (diff_r * wi + diff_i * wr) >> (frac_length + 1)
                
                xr[idx_b] = tr
                xi[idx_b] = ti
                
    return xr.astype(np.int32), xi.astype(np.int32)

# --- Configuration ---
N = 1024
word_length = 16
frac_length = 13

# Generate weights (N/2 = 512 factors)
k = np.arange(N // 2)
theta = -2 * np.pi * k / N
twiddle_r = quantize(np.cos(theta), word_length, frac_length)
twiddle_i = quantize(np.sin(theta), word_length, frac_length)

# Generate and quantize input
t = np.linspace(0, 1, N, endpoint=False)
test_signal = 0.5 * np.sin(2 * np.pi * 50 * t)      + 0.1 * np.sin(2 * np.pi * 100 * t) 
xr_in = quantize(test_signal, word_length, frac_length)
xi_in = np.zeros(N, dtype=np.int32)

# Compute output
res_r, res_i = fft_1024_fixed_dif(xr_in, xi_in, twiddle_r, twiddle_i)

# Save input, weights, output in hex (16b Re, 16b Im)
input_32bit = (xr_in.astype(np.uint32) << 16) | (xi_in.astype(np.uint32) & 0x0000FFFF)
np.savetxt('fft.in', input_32bit, fmt='%08x')
weights_32bit = (twiddle_r.astype(np.uint32) << 16) | (twiddle_i.astype(np.uint32) & 0x0000FFFF)
np.savetxt('weights.in', weights_32bit, fmt='%08x')
output_32bit = (res_r.astype(np.uint32) << 16) | (res_i.astype(np.uint32) & 0x0000FFFF)
np.savetxt('fft.out', output_32bit, fmt='%08x')
print("Saved packed bit-reversed FFT result to fft.in, weights.in, fft.out")

# --- Simple analysis  ---
# Because DIF output is bit-reversed, we must re-order to find frequencies
mag = np.sqrt(res_r.astype(np.float64)**2 + res_i.astype(np.float64)**2)
natural_mag = np.zeros(N)
for i in range(N):
    natural_mag[bit_reverse_val(i, 10)] = mag[i]

top_indices = np.argsort(natural_mag)[-5:][::-1]
print(f"\nTop Peaks (Natural Order):")
for idx in top_indices:
    print(f"Freq: {idx} Hz | Raw Mag: {natural_mag[idx]:.1f}")


# TODO: compute MSE