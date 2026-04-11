These files store FFT twiddle factors for a 1024-point FFT.
You do NOT need to use the given twiddle factors. You can make your own.

- twiddle_fp32.hex
  - 64-bit per line: first 8 hexadeciamls is real part in FP32 (next 8 hexadeciamls in imaginary part in FP32)
- twiddle_q15.hex
  - 32-bit per line
  - first 4 hexa: real part in Q1.15
  - next 4 hexa: imaginary part in Q1.15
(The real and imaginary parts are concatenated directly with no separator.)

Each line stores one complex twiddle factor $W_N^k = e^{-j 2\pi k / N}$ with N = 1024 and k = 0, 1, ..., 511.

Only 512 entries are stored because a radix-2 FFT can reuse these coefficients across stages.

```
k     | Twiddle                    | FP32 Hex         | Q1.15 Hex
------+----------------------------+------------------+----------
0     | W_N^0 = 1 + j0             | 3F80000000000000 | 7FFF0000
1     | W_N^1 = cos(2π/N) - jsin() | 3F7FFEC4BBC90F88 | 7FFFFF37
2     | W_N^2                      | 3F7FFB11BC490E90 | 7FFEFE6E
...   | ...                        | ...              | ...
N/2-1 | W_N^511                    | BF7FFEC4BBC90F88 | 8001FF37
```
