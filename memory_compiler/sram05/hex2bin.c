#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <input_hex_file> <output_bin_file>\n", argv[0]);
        return 1;
    }

    FILE *f_in = fopen(argv[1], "r");
    FILE *f_out = fopen(argv[2], "w");

    if (!f_in || !f_out) {
        printf("Error: Could not open files.\n");
        return 1;
    }

    uint32_t val;
    int count = 0;

    // Read hex values one by one
    while (fscanf(f_in, "%x", &val) == 1) {
        // Convert the 32-bit value to a string of '0's and '1's
        for (int i = 31; i >= 0; i--) {
            fprintf(f_out, "%c", ((val >> i) & 1) ? '1' : '0');
        }
        fprintf(f_out, "\n");
        count++;
    }

    fclose(f_in);
    fclose(f_out);

    printf("Successfully converted %d words to binary format.\n", count);
    return 0;
}