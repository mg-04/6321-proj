`timescale 1ns/1ps
`define DELAY #1

module sram_wrapper01 # (
    parameter DW = 32,
    parameter AW = 9
) (
    input clk,
    input cen,
    input gwen,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

    wire cen_delayed;
    wire gwen_delayed;
    wire [AW-1:0] addr_delayed;
    wire [DW-1:0] din_delayed;
   
    assign `DELAY cen_delayed = cen;
    assign `DELAY gwen_delayed = gwen;
    assign `DELAY addr_delayed = addr;
    assign `DELAY din_delayed = din;

    wire [31:0] w_dout;
    assign dout = w_dout[DW-1:0];

    sram01 sram01_inst (
        .CLK(clk),
        .CEN(cen_delayed),
        .GWEN(gwen_delayed),
        .WEN(4'b0000),
        .A(addr_delayed),
        .D(din_delayed),
        .EMA(3'b000),
        .RETN(1'b1),
        .Q(w_dout)
    );


endmodule