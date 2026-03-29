// Dummy behavioral model for a 512x32 single-port synchronous SRAM
`timescale 1ns/1ps

module sram01 (
    input           CLK,
    input           CEN,
    input           GWEN,
    input  [3:0]    WEN,
    input  [8:0]    A,
    input  [31:0]   D,
    output [31:0]   Q,

    // Unused control signals (for interface compatibility)
    input  [2:0]    EMA,
    input           RETN
);

    // Memory array: 512 entries x 32 bits
    reg [31:0] mem [0:511];

    // Output register for synchronous read behavior
    reg [31:0] q_reg;

    assign Q = q_reg;

    // Port logic: handles reads and writes on the rising edge of CLK
    always @(posedge CLK) begin
        if (~CEN) begin // Chip Enable is active-low
            if (~GWEN) begin // Global Write Enable is active-low
                // Note: WEN is ignored and a full 32-bit write is performed
                mem[A] <= D;
            end
            // A read always occurs, capturing the memory state before the write
            q_reg <= mem[A];
        end
    end

endmodule
