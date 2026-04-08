#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define N 1024
#define NUM_TESTS 1024

uint32_t pack_hex(int16_t r, int16_t i) {
    return ((uint32_t)(uint16_t)r << 16) | (uint16_t)i;
}

// Helper to catch overflows, warn, and simulate hardware wrapping
int16_t wrap_and_warn(int32_t val, int stage) {
    if (val > 32767 || val < -32768) {
        static int warn_count = 0;
        if (warn_count < 15) { // Limit prints so the terminal doesn't crash
            printf("WARNING: Overflow at stage %d! Value %d wraps to %d\n", 
                    stage, val, (int16_t)val);
            warn_count++;
            if (warn_count == 15) {
                printf("  ... suppressing further overflow warnings.\n");
            }
        }
    }
    return (int16_t)val;
}

// Changed to return int32_t so we don't silently wrap before checking
int32_t round_half_even_s1(int32_t val) {
    return (val + ((val & 1) && ((val >> 1) & 1))) >> 1;
}

// Changed to return int32_t
int32_t round_half_even_s15(int64_t val) {
    int64_t mask = (1LL << 15) - 1;
    int64_t half = (1LL << 14);
    
    uint16_t frac = (uint16_t)(val & mask);
    int32_t res_lsb = (int32_t)((val >> 15) & 1);

    if (frac < half) {
        return (int32_t)(val >> 15);    
    } else if (frac > half) {
        return (int32_t)((val + (1LL << 15)) >> 15); 
    } else {        
        return (int32_t)((val >> 15) + res_lsb);
    }
}

// Changed to return int32_t
int32_t round_half_even_s16(int64_t val) {
    int64_t mask = (1LL << 16) - 1;
    int64_t half = (1LL << 15);
    
    uint16_t frac = (uint16_t)(val & mask);
    int32_t res_lsb = (int32_t)((val >> 16) & 1);

    if (frac < half) {
        return (int32_t)(val >> 16);    
    } else if (frac > half) {
        return (int32_t)((val + (1LL << 16)) >> 16); 
    } else {        
        return (int32_t)((val >> 16) + res_lsb);
    }
}

// does one set of FFT
void fft_1024_fixed_dif(int16_t *xr, int16_t *xi, int16_t *tw_r, int16_t *tw_i, FILE *log_fp) {
    for (int stage = 0; stage < 10; stage++) {
        int stride = 512 >> stage;
        int num_groups = 1 << stage;
        uint16_t scale_mask = 0b1111001111;

        for (int g = 0; g < num_groups; g++) {
            int group_start = g * (2 * stride);
            for (int i = 0; i < stride; i++) {
                int idx_a = group_start + i;
                int idx_b = group_start + i + stride;
                int tw_idx = i << stage;

                int16_t wr = tw_r[tw_idx];
                int16_t wi = tw_i[tw_idx];
                int16_t a_r_in = xr[idx_a];
                int16_t a_i_in = xi[idx_a];
                int16_t b_r_in = xr[idx_b];
                int16_t b_i_in = xi[idx_b];

                // --- Butterfly Calculation ---
                
                // Stage 1: Sum path (X0)
                int32_t sum_r = (int32_t)a_r_in + (int32_t)b_r_in;
                int32_t sum_i = (int32_t)a_i_in + (int32_t)b_i_in;
                
                int32_t temp_x0_r, temp_x0_i;
                int scale = (scale_mask >> stage) & 1;
                if (scale) {
                    temp_x0_r = round_half_even_s1(sum_r);
                    temp_x0_i = round_half_even_s1(sum_i);
                } else {
                    temp_x0_r = sum_r;
                    temp_x0_i = sum_i;
                }
                
                // Route through the overflow checker
                int16_t x0_r = wrap_and_warn(temp_x0_r, stage);
                int16_t x0_i = wrap_and_warn(temp_x0_i, stage);

                // Stage 2: Diff/Mult path (X1)
                int32_t diff_r = a_r_in - b_r_in;
                int32_t diff_i = a_i_in - b_i_in;

                int64_t tr_full = (int64_t)diff_r * wr - (int64_t)diff_i * wi;
                int64_t ti_full = (int64_t)diff_r * wi + (int64_t)diff_i * wr;

                int32_t temp_x1_r, temp_x1_i;
                if (scale) {
                    temp_x1_r = round_half_even_s16(tr_full);
                    temp_x1_i = round_half_even_s16(ti_full);
                } else {
                    temp_x1_r = round_half_even_s15(tr_full);
                    temp_x1_i = round_half_even_s15(ti_full);
                }
                
                // Route through the overflow checker
                int16_t x1_r = wrap_and_warn(temp_x1_r, stage);
                int16_t x1_i = wrap_and_warn(temp_x1_i, stage);

                if (log_fp) {
                    fprintf(log_fp, "%08x %08x %08x %08x %08x\n", 
                            pack_hex(a_r_in, a_i_in), 
                            pack_hex(b_r_in, b_i_in), 
                            pack_hex(wr, wi), 
                            pack_hex(x0_r, x0_i), 
                            pack_hex(x1_r, x1_i));
                }

                // Update Array for next stage
                xr[idx_a] = x0_r; xi[idx_a] = x0_i;
                xr[idx_b] = x1_r; xi[idx_b] = x1_i;
            }
        }
    }
}

int main() {
    int16_t *tw_r = malloc(512 * sizeof(int16_t));
    int16_t *tw_i = malloc(512 * sizeof(int16_t));
    int16_t *xr = malloc(N * sizeof(int16_t));
    int16_t *xi = malloc(N * sizeof(int16_t));

    FILE *f_tw = fopen("FFT_input/twiddle_q15.hex", "r");
    FILE *f_in = fopen("FFT_input/input_q1_15_v3.hex", "r");
    FILE *f_out = fopen("FFT_input/output_q1_15.hex", "w");
    FILE *f_log = fopen("FFT_input/c_alu_trace.txt", "w");

    if (!f_tw || !f_in || !f_out || !f_log) {
        printf("Error: Could not open required files.\n");
        return 1;
    }

    // Load manual twiddles from weights.in
    uint32_t val;
    for (int k = 0; k < 512; k++) {
        if (fscanf(f_tw, "%x", &val) != 1) break;
        tw_r[k] = (int16_t)(val >> 16);
        tw_i[k] = (int16_t)(val & 0xFFFF);
    }
    fclose(f_tw);

    // run every test case!
    printf("Processing 1024 tests...\n");   
    for (int t = 0; t < NUM_TESTS; t++) {       
        for (int i = 0; i < N; i++) {
            if (fscanf(f_in, "%x", &val) != 1) goto end_loop;
            xr[i] = (int16_t)(val);
            xi[i] = (int16_t)(0);
        }

        fft_1024_fixed_dif(xr, xi, tw_r, tw_i, f_log);
        for (int i = 0; i < N; i++) {
            uint32_t packed = ((uint32_t)(uint16_t)xr[i] << 16) | (uint16_t)xi[i];
            fprintf(f_out, "%08x\n", packed);
        }
    }

end_loop:
    fclose(f_in);
    fclose(f_out);
    fclose(f_log);
    printf("Done\n");

    free(tw_r); free(tw_i); free(xr); free(xi);
    return 0;
}