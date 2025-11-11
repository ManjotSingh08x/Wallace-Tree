`timescale 1ns / 1ps

module full_adder(
    input a,
    input b,
    input cin,
    output cout,
    output s
    );
    assign s = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

module half_adder(
    input a,
    input b,
    output s,
    output cout
    );
    assign s = a ^ b; 
    assign cout = a & b;
endmodule

module array_mult(
    input [15:0] a,
    input [15:0] b,
    output [31:0] p
    );
    logic [15:0] a1; logic [15:0] b1;
    always_ff @(posedge clk)
        a1 <= 
    genvar i, j; 
    wire [15:0] pp [0:15];
    generate
        for (i = 0; i < 16; i = i + 1) begin : pp_row_gen
            for (j = 0; j < 16; j = j + 1) begin : pp_col_gen
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate 
    wire [15:0] s_bus [0:14];
    wire [15:0] c_bus [0:14];
    
    assign p[0] = pp[0][0];
    half_adder ha_0 (
        .a(pp[0][1]),
        .b(pp[1][0]),
        .s(s_bus[0][0]),
        .cout(c_bus[0][0])
    );
    generate 
        for (j = 1; j < 15; j = j+1) begin : row_0_fa_gen
            full_adder fa (
                .a(pp[0][j+1]),
                .b(pp[1][j]),
                .cin(c_bus[0][j-1]),
                .s(s_bus[0][j]),
                .cout(c_bus[0][j])
            );
        end
    endgenerate

    full_adder fa_0_15 (
        .a(1'b0),
        .b(pp[1][15]),
        .cin(c_bus[0][14]),
        .s(s_bus[0][15]),
        .cout(c_bus[0][15])
    );
    generate
        for (i = 1; i < 15; i = i + 1) begin : csa_row_gen
            assign p[i] = s_bus[i-1][0];
            half_adder ha (
                .a(s_bus[i-1][1]),
                .b(pp[i+1][0]),
                .s(s_bus[i][0]),
                .cout(c_bus[i][0])
            );
            for (j = 1; j < 15;j = j + 1) begin : csa_col_gen
                full_adder fa (
                    .a(s_bus[i-1][j+1]),
                    .b(pp[i+1][j]),
                    .cin(c_bus[i][j-1]),
                    .s(s_bus[i][j]),
                    .cout(c_bus[i][j])
                );
            end
            full_adder fa_last (
            // changes are done here from .a(1'b0)
                .a(c_bus[i-1][15]),
                .b(pp[i+1][15]),
                .cin(c_bus[i][14]),
                .s(s_bus[i][15]),
                .cout(c_bus[i][15])
            );
        end
   endgenerate
    assign p[15] = s_bus[14][0];
    assign p[30:16] = s_bus[14][15:1];
    assign p[31] = c_bus[14][15];
endmodule
