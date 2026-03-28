// dual-port sram

`timescale 1ns/1ps
`define DELAY #1

module sram_wrapper02 # (
    parameter DW = 32,	// 16 re, 16 im
    parameter AW = 10	// 1024-point
) (
    input clk,
    input cen,				// chip enable
    input gwen,				// global write enable
    input [AW-1:0] addr1,
    input [AW-1:0] addr2,
    input [DW-1:0] din1,
    input [DW-1:0] din2,
    output [DW-1:0] dout1,
    output [DW-1:0] dout2
);

	// internal delayed signals
	wire cen1_d, gwen1_d;
    wire [AW-1:0] addr1_d;
    wire [DW-1:0] din1_d;
    assign `DELAY cen1_d   = cen;
    assign `DELAY gwen1_d  = gwen;
    assign `DELAY addr1_d  = addr1;
    assign `DELAY din1_d   = din1;

    wire cen2_d, gwen2_d;
    wire [AW-1:0] addr2_d;
    wire [DW-1:0] din2_d;
    assign `DELAY cen2_d   = cen;
    assign `DELAY gwen2_d  = gwen;
    assign `DELAY addr2_d  = addr2;
    assign `DELAY din2_d   = din2;

    wire [DW-1:0] w_dout_a;
    wire [DW-1:0] w_dout_b;
    assign dout1 = w_dout_a;
	assign dout2 = w_dout_b;

    sram02 sram02_inst (
        .CLKA(clk),
        .CENA(cen1_d),
        .GWENA(gwen1_d),
        .WENA(4'b0000),      // Enable all 4 bytes
        .AA(addr1_d),
        .DA(din1_d),
        .QA(w_dout_a),
        .EMAA(3'b000),       // Extra Margin Adjustment A

        // --- PORT B (Tied to Idle) ---
        .CLKB(clk),
        .CENB(cen2_d),
        .GWENB(gwen2_d),
        .WENB(4'b0000),
        .AB(addr2_d),
        .DB(din2_d),
        .QB(w_dout_b),
        .EMAB(3'b000),       // Extra Margin Adjustment B

        // --- System Signals ---
        .RETN(1'b1)          // Normal mode (1=Active, 0=Retention)
    );

endmodule