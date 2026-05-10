#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

// Helper to mimic Verilog's Round-to-Nearest-Even
int16_t round_to_nearest_even(int64_t val, int shift) {
    if (shift <= 0) return (int16_t)val;
    
    int64_t mask_sticky = (1LL << (shift - 1)) - 1;
    int bit_05 = (val >> (shift - 1)) & 1;   // The "half" bit
    int lsb    = (val >> shift) & 1;         // The LSB of the result
    int sticky = (val & mask_sticky) != 0;   // Any bits below the half bit
    
    int64_t result = val >> shift;
    if (bit_05 && (lsb || sticky)) {
        result += 1;
    }
    return (int16_t)result;
}

void write_test_case(FILE *in, FILE *gold, int scale, 
                     int16_t x0r, int16_t x0i, 
                     int16_t x1r, int16_t x1i, 
                     int16_t wr, int16_t wi) {
    
    // 1. Calculate X0 = x0 + x1
    int32_t sum_r = (int32_t)x0r + x1r;
    int32_t sum_i = (int32_t)x0i + x1i;
    
    int16_t X0r, X0i;
    if (scale) {
        // Mimic Verilog: (sum + (bit0 & bit1)) >>> 1
        X0r = (int16_t)((sum_r + ((sum_r & 1) && (sum_r & 2))) >> 1);
        X0i = (int16_t)((sum_i + ((sum_i & 1) && (sum_i & 2))) >> 1);
    } else {
        X0r = (int16_t)sum_r;
        X0i = (int16_t)sum_i;
    }

    // 2. Calculate X1 = (x0 - x1) * W
    int32_t diff_r = (int32_t)x0r - x1r;
    int32_t diff_i = (int32_t)x0i - x1i;

    // Complex multiplication: (diff_r + j*diff_i) * (wr + j*wi)
    // Real = dr*wr - di*wi | Imag = dr*wi + di*wr
    int64_t p_rr = (int64_t)diff_r * wr;
    int64_t p_ii = (int64_t)diff_i * wi;
    int64_t p_ri = (int64_t)diff_r * wi;
    int64_t p_ir = (int64_t)diff_i * wr;

    int64_t full_X1r = p_rr - p_ii;
    int64_t full_X1i = p_ri + p_ir;

    // 3. Apply Scaling and Rounding for X1
    // If scale=1: we shift by 15 (mult) + 1 (scale) = 16
    // If scale=0: we shift by 15
    int16_t X1r = round_to_nearest_even(full_X1r, scale ? 16 : 15);
    int16_t X1i = round_to_nearest_even(full_X1i, scale ? 16 : 15);

    // Write Input: scale x0r x0i x1r x1i wr wi (as 16-bit hex)
    fprintf(in, "%d %04hx %04hx %04hx %04hx %04hx %04hx\n", 
            scale, (uint16_t)x0r, (uint16_t)x0i, (uint16_t)x1r, (uint16_t)x1i, (uint16_t)wr, (uint16_t)wi);
    
    // Write Golden: X0r X0i X1r X1i
    fprintf(gold, "%04hx %04hx %04hx %04hx\n", 
            (uint16_t)X0r, (uint16_t)X0i, (uint16_t)X1r, (uint16_t)X1i);
}

int main() {
    FILE *f_in = fopen("alu_input.hex", "w");
    FILE *f_gold = fopen("alu_golden.hex", "w");

    if (!f_in || !f_gold) return 1;

    // Case 1: Simple Pass-through (W=1.0, No Scale)
    // 0x7FFF is approx 1.0 in Q1.15
    write_test_case(f_in, f_gold, 0, 1000, 0, 500, 0, 0x7FFF, 0);

    // Case 2: Scaling test
    write_test_case(f_in, f_gold, 1, 4000, 4000, 2000, 2000, 0x4000, 0);

    // Case 3: Random Tests
    for(int i = 0; i < 98; i++) {
        write_test_case(f_in, f_gold, rand()%2, 
                        rand()%65536 - 32768, rand()%65536 - 32768,
                        rand()%65536 - 32768, rand()%65536 - 32768,
                        rand()%65536 - 32768, rand()%65536 - 32768);
    }

    fclose(f_in);
    fclose(f_gold);
    printf("Done! Generated alu_input.hex and alu_golden.hex\n");
    return 0;
}