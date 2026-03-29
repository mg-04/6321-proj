// Dummy behavioral model for a 1024x32 dual-port synchronous SRAM
`timescale 1ns/1ps

module sram02 (
    // Port A
    input           CLKA,
    input           CENA,
    input           GWENA,
    input  [3:0]    WENA,
    input  [9:0]    AA,
    input  [31:0]   DA,
    output [31:0]   QA,

    // Port B
    input           CLKB,
    input           CENB,
    input           GWENB,
    input  [3:0]    WENB,
    input  [9:0]    AB,
    input  [31:0]   DB,
    output [31:0]   QB,

    // Unused control signals (for interface compatibility)
    input  [2:0]    EMAA,
    input  [2:0]    EMAB,
    input           RETN
);

    // Memory array: 1024 entries x 32 bits
    reg [31:0] mem [0:1023];

    // Output registers for synchronous read behavior
    reg [31:0] qa_reg;
    reg [31:0] qb_reg;

    assign QA = qa_reg;
    assign QB = qb_reg;

    // Port A logic: handles reads and writes on the rising edge of CLKA
    always @(posedge CLKA) begin
        if (~CENA) begin // Chip Enable is active-low
            if (~GWENA) begin // Global Write Enable is active-low
                // Note: WENA is ignored and a full 32-bit write is performed
                mem[AA] <= DA;
            end
            // A read always occurs, capturing the memory state before the write
            qa_reg <= mem[AA];
        end
    end

    // Port B logic: handles reads and writes on the rising edge of CLKB
    always @(posedge CLKB) begin
        if (~CENB) begin // Chip Enable is active-low
            if (~GWENB) begin // Global Write Enable is active-low
                mem[AB] <= DB;
            end
            // A read always occurs
            qb_reg <= mem[AB];
        end
    end

endmodule
