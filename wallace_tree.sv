`timescale 1ns/1ps

// Different Variety of Adders
module half_a (
    input  logic a, b,
    output logic sum, carry
);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

module full_a (
    input  logic a, b, cin,
    output logic sum, carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = (a & b) | (b & cin) | (cin & a);
endmodule

module ripple_carry_adder_32 (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic             Cin,
    output logic [31:0] Sum,
    output logic             Cout
);
    logic [32:0] C;
    assign C[0] = Cin;
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : fa_chain_n
            full_a fa_inst (
                .a(A[i]),
                .b(B[i]),
                .cin(C[i]),
                .sum(Sum[i]),
                .carry(C[i+1])
            );
        end
    endgenerate
    assign Cout = C[32];
endmodule

module brent_kung_adder_32 (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic        Cin,
    output logic [31:0] Sum,
    output logic        Cout
);
    logic [31:0] prop, gen;
    assign prop = A ^ B;
    assign gen = A & B;
    logic [31:0] gen_pre, prop_pre;
    always_comb begin
        logic [31:0] gen_up1, prop_up1; 
        logic [31:0] gen_up2, prop_up2; 
        logic [31:0] gen_up3, prop_up3; 
        logic [31:0] gen_up4, prop_up4; 
        logic [31:0] gen_up5, prop_up5; 

        for (int i = 1; i < 32; i += 2) begin // i = 1, 3, 5, ..., 31
            gen_up1[i] = gen[i] | (prop[i] & gen[i-1]);
            prop_up1[i] = prop[i] & prop[i-1];
        end
        for (int i = 3; i < 32; i += 4) begin // i = 3, 7, 11, ..., 31
            gen_up2[i] = gen_up1[i] | (prop_up1[i] & gen_up1[i-2]);
            prop_up2[i] = prop_up1[i] & prop_up1[i-2];
        end
        for (int i = 7; i < 32; i += 8) begin // i = 7, 15, 23, 31
            gen_up3[i] = gen_up2[i] | (prop_up2[i] & gen_up2[i-4]);
            prop_up3[i] = prop_up2[i] & prop_up2[i-4];
        end
        for (int i = 15; i < 32; i += 16) begin // i = 15, 31
            gen_up4[i] = gen_up3[i] | (prop_up3[i] & gen_up3[i-8]);
            prop_up4[i] = prop_up3[i] & prop_up3[i-8];
        end
        gen_up5[31] = gen_up4[31] | (prop_up4[31] & gen_up4[15]);
        prop_up5[31] = prop_up4[31] & prop_up4[15];
        gen_pre = '0;
        prop_pre = '0;
        gen_pre[0] = gen[0];
        prop_pre[0] = prop[0];
        gen_pre[1] = gen_up1[1];  prop_pre[1] = prop_up1[1];
        gen_pre[3] = gen_up2[3];  prop_pre[3] = prop_up2[3];
        gen_pre[5] = gen_up1[5] | (prop_up1[5] & gen_pre[3]);
        prop_pre[5] = prop_up1[5] & prop_pre[3];
        gen_pre[7] = gen_up3[7];  prop_pre[7] = prop_up3[7];
        gen_pre[9] = gen_up1[9] | (prop_up1[9] & gen_pre[7]);
        prop_pre[9] = prop_up1[9] & prop_pre[7];
        gen_pre[11] = gen_up2[11] | (prop_up2[11] & gen_pre[7]);
        prop_pre[11] = prop_up2[11] & prop_pre[7];
        gen_pre[13] = gen_up1[13] | (prop_up1[13] & gen_pre[11]);
        prop_pre[13] = prop_up1[13] & prop_pre[11];
        gen_pre[15] = gen_up4[15]; prop_pre[15] = prop_up4[15];
        gen_pre[17] = gen_up1[17] | (prop_up1[17] & gen_pre[15]);
        prop_pre[17] = prop_up1[17] & prop_pre[15];
        gen_pre[19] = gen_up2[19] | (prop_up2[19] & gen_pre[15]);
        prop_pre[19] = prop_up2[19] & prop_pre[15];
        gen_pre[21] = gen_up1[21] | (prop_up1[21] & gen_pre[19]);
        prop_pre[21] = prop_up1[21] & prop_pre[19];
        gen_pre[23] = gen_up3[23] | (prop_up3[23] & gen_pre[15]);
        prop_pre[23] = prop_up3[23] & prop_pre[15];
        gen_pre[25] = gen_up1[25] | (prop_up1[25] & gen_pre[23]);
        prop_pre[25] = prop_up1[25] & prop_pre[23];
        gen_pre[27] = gen_up2[27] | (prop_up2[27] & gen_pre[23]);
        prop_pre[27] = prop_up2[27] & prop_pre[23];
        gen_pre[29] = gen_up1[29] | (prop_up1[29] & gen_pre[27]);
        prop_pre[29] = prop_up1[29] & prop_pre[27];
        gen_pre[31] = gen_up5[31]; prop_pre[31] = prop_up5[31];
        for (int i = 2; i < 32; i += 2) begin
            gen_pre[i] = gen[i] | (prop[i] & gen_pre[i-1]);
            prop_pre[i] = prop[i] & prop_pre[i-1];
        end
    end
    logic [31:0] c;
    assign c[0] = Cin;
    // Generate carries for bits 1 through 31
    generate
        genvar j;
        for (j = 1; j < 32; j++) begin : CARRY_GEN
            assign c[j] = gen_pre[j-1] | (prop_pre[j-1] & Cin);
        end
    endgenerate
    assign Sum = prop ^ c;
    assign Cout = gen_pre[31] | (prop_pre[31] & Cin);
endmodule

module kogge_stone_adder_32 (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic        Cin,
    output logic [31:0] Sum,
    output logic        Cout
);
    logic [32-1:0] gen [0:5];
    logic [32-1:0] prop [0:5];
    genvar i;
    generate
        for (i = 0; i < 32; i++) begin
            assign gen[0][i] = A[i] & B[i];
            assign prop[0][i] = A[i] ^ B[i];
        end
    endgenerate
    genvar s;
    generate
        for (s = 1; s <= 5; s++) begin : prefix_stages
            localparam int DIST = 1 << (s - 1);
            for (i = 0; i < 32; i++) begin : prefix_bits
                if (i >= DIST) begin
                    assign gen[s][i] = gen[s-1][i] | (prop[s-1][i] & gen[s-1][i-DIST]);
                    assign prop[s][i] = prop[s-1][i] & prop[s-1][i-DIST];
                end else begin
                    assign gen[s][i] = gen[s-1][i];
                    assign prop[s][i] = prop[s-1][i];
                end
            end
        end
    endgenerate
    logic [32:0] C;
    assign C[0] = Cin;

    generate
        for (i = 0; i < 32; i++) begin
            assign C[i+1] = gen[5][i] | (prop[5][i] & Cin);
            assign Sum[i] = prop[0][i] ^ C[i];
        end
    endgenerate
    assign Cout = C[32];
endmodule

module han_carlson_adder_32 (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic        Cin,
    output logic [31:0] Sum,
    output logic        Cout
);
    // --- 1. Pre-computation (Initial g and p) ---
    logic [32-1:0] gen_pre;
    logic [32-1:0] prop_pre;

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin
            assign gen_pre[i] = A[i] & B[i];
            assign prop_pre[i] = A[i] ^ B[i];
        end
    endgenerate

    // --- 2. Grouping & Prefix Network ---
    logic [16-1:0] gen_block [0:4];
    logic [16-1:0] prop_block [0:4];

    genvar k, s;
    generate
        for (k = 0; k < 16; k++) begin
            assign gen_block[0][k] = gen_pre[2*k + 1] | (prop_pre[2*k + 1] & gen_pre[2*k]);
            assign prop_block[0][k] = prop_pre[2*k + 1] & prop_pre[2*k];
        end
    endgenerate
    generate
        for (s = 1; s <= 4; s++) begin : prefix_stages
            // dist = 1, 2, 4, 8
            localparam int DIST = 1 << (s - 1); 
            for (k = 0; k < 16; k++) begin : prefix_bits
                if (k >= DIST) begin
                    assign gen_block[s][k] = gen_block[s-1][k] | (prop_block[s-1][k] & gen_block[s-1][k-DIST]);
                    assign prop_block[s][k] = prop_block[s-1][k] & prop_block[s-1][k-DIST];
                end else begin
                    assign gen_block[s][k] = gen_block[s-1][k];
                    assign prop_block[s][k] = prop_block[s-1][k];
                end
            end
        end
    endgenerate
    // --- 3. Carry and Sum Computation ---
    logic [32:0] C; 
    assign C[0] = Cin;
    generate
        for (k = 0; k < 16; k++) begin
            assign C[2*k] = (k == 0) ? Cin : (gen_block[4][k-1] | (prop_block[4][k-1] & Cin));
            assign Sum[2*k] = prop_pre[2*k] ^ C[2*k];
            assign C[2*k + 1] = gen_pre[2*k] | (prop_pre[2*k] & C[2*k]);
            assign Sum[2*k + 1] = prop_pre[2*k + 1] ^ C[2*k + 1];
        end
    endgenerate
    assign Cout = gen_block[4][16-1] | (prop_block[4][16-1] & Cin);
endmodule


// Carry Lookahead Adder Blocks 
module carry_lookahead_4bit_block (
    input  logic [3:0] A,
    input  logic [3:0] B,
    input  logic       Cin,
    output logic [3:0] Sum,
    output logic       Block_G, 
    output logic       Block_P  
);
    logic [3:0] gen;
    logic [3:0] prop;
    logic [3:0] c;
    assign prop[0] = A[0] ^ B[0];
    assign gen[0] = A[0] & B[0];
    assign prop[1] = A[1] ^ B[1];
    assign gen[1] = A[1] & B[1];
    assign prop[2] = A[2] ^ B[2];
    assign gen[2] = A[2] & B[2];
    assign prop[3] = A[3] ^ B[3];
    assign gen[3] = A[3] & B[3];
    assign c[0] = Cin;
    assign c[1] = gen[0] | (prop[0] & c[0]);
    assign c[2] = gen[1] | (prop[1] & gen[0]) | (prop[1] & prop[0] & c[0]);
    assign c[3] = gen[2] | (prop[2] & gen[1]) | (prop[2] & prop[1] & gen[0]) | 
                (prop[2] & prop[1] & prop[0] & c[0]);
    logic c4;
    assign c4 = gen[3] | (prop[3] & gen[2]) | (prop[3] & prop[2] & gen[1]) | 
                (prop[3] & prop[2] & prop[1] & gen[0]) | (prop[3] & prop[2] & prop[1] & prop[0] & c[0]);
    assign Sum[0] = prop[0] ^ c[0];
    assign Sum[1] = prop[1] ^ c[1];
    assign Sum[2] = prop[2] ^ c[2];
    assign Sum[3] = prop[3] ^ c[3];
    assign Block_G = gen[3] | (prop[3] & gen[2]) | (prop[3] & prop[2] & gen[1]) | 
                (prop[3] & prop[2] & prop[1] & gen[0]);
    assign Block_P = prop[3] & prop[2] & prop[1] & prop[0];
endmodule

module carry_lookahead_4block_lcu (
    input  logic [3:0] gen_in,   
    input  logic [3:0] prop_in,   
    input  logic       carry_in,   
    output logic [3:0] carry_out,   
    output logic       Super_G, 
    output logic       Super_P  
);
    assign carry_out[0] = carry_in;
    assign carry_out[1] = gen_in[0] | (prop_in[0] & carry_in);
    assign carry_out[2] = gen_in[1] | (prop_in[1] & gen_in[0]) | 
                      (prop_in[1] & prop_in[0] & carry_in);
    assign carry_out[3] = gen_in[2] | (prop_in[2] & gen_in[1]) |
                      (prop_in[2] & prop_in[1] & gen_in[0]) |
                      (prop_in[2] & prop_in[1] & prop_in[0] & carry_in);
    assign Super_G = gen_in[3] | (prop_in[3] & gen_in[2]) |
                     (prop_in[3] & prop_in[2] & gen_in[1]) |
                     (prop_in[3] & prop_in[2] & prop_in[1] & gen_in[0]);
    assign Super_P = prop_in[3] & prop_in[2] & prop_in[1] & prop_in[0];

endmodule

module carry_lookahead_adder_32 (
    input  logic [31:0] A,
    input  logic [31:0] B,
    input  logic        Cin,
    output logic [31:0] Sum,
    output logic        Cout
);
    logic [3:0] level1_g;
    logic [3:0] level1_p;
    logic [3:0] level2_cin;
    logic [1:0] level2_super_g;
    logic [1:0] level2_super_p;
    logic c_into_lcu1;
    assign c_into_lcu1 = level2_super_g[0] | (level2_super_p[0] & Cin);
    assign Cout = level2_super_g[1] | (level2_super_p[1] & c_into_lcu1);
    carry_lookahead_4block_lcu lcu_0 (
        .gen_in(level1_g[3:0]),
        .prop_in(level1_p[3:0]),
        .carry_in(Cin),
        .carry_out(level2_cin[3:0]),    // Carries for blocks 0, 1, 2, 3
        .Super_G(level2_super_g[0]),
        .Super_P(level2_super_p[0])
    );
    carry_lookahead_4block_lcu lcu_1 (
        .gen_in(level1_g[7:4]),
        .prop_in(level1_p[7:4]),
        .carry_in(carry_into_lcu1),
        .carry_out(level2_cin[7:4]),    // Carries for blocks 4, 5, 6, 7
        .Super_G(level2_super_g[1]),
        .Super_P(level2_super_p[1])
    );
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : carry_lookahead_blocks
            localparam int base = i * 4;
            carry_lookahead_4bit_block block_inst (
                .A(A[base+3:base]),
                .B(B[base+3:base]),
                .Cin(level2_cin[i]),
                .Sum(Sum[base+3:base]),
                .Block_G(level1_g[i]),
                .Block_P(level1_p[i])
            );
        end
    endgenerate
endmodule

// Compressor used
module comp4_2 (
    input  logic i0, i1, i2, i3, cin, 
    output logic sum, carry, cout     
);
    logic s1, c1;
    full_a fa1 (
        .a(i0), .b(i1), .cin(i2),
        .sum(s1), .carry(c1)
    );
    full_a fa2 (
        .a(s1), .b(i3), .cin(cin),
        .sum(sum), .carry(carry)
    );
    assign cout = c1;
endmodule

module wallace_mult (
    input logic clk,
    input logic [15:0]A, [15:0]B,
    (* IOB = "TRUE" *) output logic [31:0]P
);

    logic [15:0] A_reg; logic [15:0] B_reg;
    always_ff @(posedge clk) begin
        A_reg <= A; B_reg <= B;
    end
//------------------------------------------Pipeline 1----------------------------------//
    logic [31:0] pprod [15:0];
    genvar i, j; 
    generate
        for (i = 0; i < 16; i++) begin : gen_partial_prods
            logic [15:0] partial_prod;
            for (j = 0; j < 16; j++) begin : gen_pp_columns
                assign partial_prod[j] = A_reg[j] & B_reg[i];
            end
//            always_ff @(posedge clk) begin
            assign pprod[i] = {16'b0, partial_prod} << i;
//            end
        end
    endgenerate
//------------------------------------------Pipeline 2----------------------------------//
    logic [31:0]stage1[7:0];
    logic [31:0]cout1[3:0];
    logic [31:0]stage1_reg[7:0];

    // First row of compressors
    assign stage1[0][0] = pprod[0][0];
    half_a ha1_0_1(pprod[0][1], pprod[1][1], stage1[0][1], stage1[0][2]);

    full_a fa1_0_2(pprod[0][2],pprod[1][2],pprod[2][2],stage1[1][2], stage1[0][3]);
    assign cout1[0][2] = 0;

    genvar k;
    generate
        for(k=3;k<=15;k++) begin : compressor1_row_1
            comp4_2 row1_1(pprod[0][k],pprod[1][k],pprod[2][k],pprod[3][k],cout1[0][k-1],stage1[1][k],stage1[0][k+1],cout1[0][k]);
        end 
    endgenerate

    comp4_2 comp1_1_16(1'b0,pprod[1][16],pprod[2][16],pprod[3][16],cout1[0][15],stage1[1][16],stage1[0][17],cout1[0][16]);
    full_a fa1_1_17(pprod[2][17],pprod[3][17],cout1[0][16], stage1[1][17], stage1[0][18]);
    assign stage1[1][18] = pprod[3][18];

    // Second row of compressors 
    assign stage1[2][4] = pprod[4][4];
    half_a ha1_4_5(pprod[4][5], pprod[5][5], stage1[2][5], stage1[2][6]);
    full_a fa1_4_6(pprod[4][6],pprod[5][6],pprod[6][6],stage1[3][6], stage1[2][7]);
    assign cout1[1][6] = 0;

    genvar l;
    generate
        for(l=7;l<=19;l++) begin : compressor1_row_2
            comp4_2 row1_2(pprod[4][l],pprod[5][l],pprod[6][l],pprod[7][l],cout1[1][l-1],stage1[3][l],stage1[2][l+1],cout1[1][l]);
        end 
    endgenerate
   
    comp4_2 comp1_2_20(1'b0,pprod[5][20],pprod[6][20],pprod[7][20],cout1[1][19],stage1[3][20],stage1[2][21],cout1[1][20]);
    full_a fa1_5_21(pprod[6][21],pprod[7][21],cout1[1][20], stage1[3][21], stage1[2][22]);
    assign stage1[3][22] = pprod[7][22];

    // Third row of compressors
    assign stage1[4][8] = pprod[8][8];
    half_a ha1_8_9(pprod[8][9], pprod[9][9], stage1[4][9], stage1[4][10]);

    full_a fa1_8_10(pprod[8][10],pprod[9][10],pprod[10][10],stage1[5][10], stage1[4][11]);
    assign cout1[2][10] = 0;

    genvar m;
    generate
        for(m=11;m<=23;m++) begin : compressor1_row_3
            comp4_2 row1_3(pprod[8][m],pprod[9][m],pprod[10][m],pprod[11][m],cout1[2][m-1],stage1[5][m],stage1[4][m+1],cout1[2][m]);
        end 
    endgenerate

//    assign pprod[8][24] = 0;
   
    comp4_2 comp1_3_24(pprod[8][24],pprod[9][24],pprod[10][24],pprod[11][24],cout1[2][23],stage1[5][24],stage1[4][25],cout1[2][24]);
    full_a fa1_9_25(pprod[10][25],pprod[11][25],cout1[2][24], stage1[5][25], stage1[4][26]);
    assign stage1[5][26] = pprod[11][26];

    // Fourth row of compressors
    assign stage1[6][12] = pprod[12][12];
    half_a ha1_12_13(pprod[12][13], pprod[13][13], stage1[6][13], stage1[6][14]);

    full_a fa1_12_14(pprod[12][14],pprod[13][14],pprod[14][14],stage1[7][14], stage1[6][15]);
    assign cout1[3][14] = 0;
    genvar n;
    generate
        for(n=15;n<=27;n++) begin : compressor1_row_4
            comp4_2 row1_4(pprod[12][n],pprod[13][n],pprod[14][n],pprod[15][n],cout1[3][n-1],stage1[7][n],stage1[6][n+1],cout1[3][n]);
        end 
    endgenerate

//    assign pprod[12][28] = 0;
   
    comp4_2 comp1_4_28(pprod[12][28],pprod[13][28],pprod[14][28],pprod[15][28],cout1[3][27],stage1[7][28],stage1[6][29],cout1[3][28]);
    full_a fa1_13_29(pprod[14][29],pprod[15][29],cout1[3][28], stage1[7][29], stage1[6][30]);
    assign stage1[7][30] = pprod[15][30];

    always_ff @(posedge clk) begin
        stage1_reg <= stage1;
    end

//------------------------------------------Pipeline 3----------------------------------//
    logic [31:0]stage2[3:0];
    logic [31:0]cout2[1:0];
    logic [31:0]stage2_reg[3:0];
    
    // First row of compressors 
    assign stage2[0][0] = stage1_reg[0][0];
    assign stage2[0][1] = stage1_reg[0][1];

    half_a ha2_0_2(stage1_reg[0][2], stage1_reg[1][2], stage2[0][2], stage2[1][3]);
    half_a ha2_0_3(stage1_reg[0][3], stage1_reg[1][3], stage2[0][3], stage2[1][4]);
    full_a fa2_0_4(stage1_reg[0][4],stage1_reg[1][4],stage1_reg[2][4],stage2[0][4], stage2[1][5]);
    full_a fa2_0_5(stage1_reg[0][5],stage1_reg[1][5],stage1_reg[2][5],stage2[0][5], stage2[1][6]);
    assign cout2[0][5] = 0;

    genvar q;
    generate
        for(q = 6;q<=18;q++) begin : compressor2_row_1
            comp4_2 row2_1(stage1_reg[0][q],stage1_reg[1][q],stage1_reg[2][q],stage1_reg[3][q],cout2[0][q-1],stage2[0][q],stage2[1][q+1],cout2[0][q]);
        end
    endgenerate
    full_a fa2_1_19(stage1_reg[2][19],stage1_reg[3][19],cout2[0][18],stage2[0][19], stage2[1][20]);
    half_a ha2_2_20(stage1_reg[2][20], stage1_reg[3][20], stage2[0][20], stage2[1][21]);
    half_a ha2_2_21(stage1_reg[2][21], stage1_reg[3][21], stage2[0][21], stage2[1][22]);
    half_a ha2_2_22(stage1_reg[2][22], stage1_reg[3][22], stage2[0][22], stage2[1][23]);

    // Second row of compressors 
    assign stage2[2][8] = stage1_reg[4][8];
    assign stage2[2][9] = stage1_reg[4][9];

    half_a ha2_4_10(stage1_reg[4][10], stage1_reg[5][10], stage2[2][10], stage2[3][11]);
    half_a ha2_4_11(stage1_reg[4][11], stage1_reg[5][11], stage2[2][11], stage2[3][12]);
    full_a fa2_4_12(stage1_reg[4][12],stage1_reg[5][12],stage1_reg[6][12],stage2[2][12], stage2[3][13]);
    full_a fa2_4_13(stage1_reg[4][13],stage1_reg[5][13],stage1_reg[6][13],stage2[2][13], stage2[3][14]);
    assign cout2[1][13] = 0;

    genvar r;
    generate
        for( r= 14;r<=26;r++) begin : compressor2_row_2
            comp4_2 row2_2(stage1_reg[4][r],stage1_reg[5][r],stage1_reg[6][r],stage1_reg[7][r],cout2[1][r-1],stage2[2][r],stage2[3][r+1],cout2[1][r]);
        end
    endgenerate

    full_a fa2_5_27(stage1_reg[6][27],stage1_reg[7][27],cout2[1][26],stage2[2][27], stage2[3][28]);
    half_a ha2_6_28(stage1_reg[6][28], stage1_reg[7][28], stage2[2][28], stage2[3][29]);
    half_a ha2_6_29(stage1_reg[6][29], stage1_reg[7][29], stage2[2][29], stage2[3][30]);
    half_a ha2_6_30(stage1_reg[6][30], stage1_reg[7][30], stage2[2][30], stage2[3][31]);

    always_ff @(posedge clk) begin
        stage2_reg <= stage2;
    end
//------------------------------------------Pipeline 4----------------------------------//

    logic [31:0]stage3[1:0];
    logic [31:0]stage3_reg[1:0];
    logic [31:0]cout3[0:0];

    assign stage3[0][0] = stage2_reg[0][0];
    assign stage3[0][1] = stage2_reg[0][1];
    assign stage3[0][2] = stage2_reg[0][2];
    
    assign stage3[1][3] = 0;
    assign stage3[1][0] = 0;
    assign stage3[1][1] = 0;
    assign stage3[1][2] = 0;
    half_a ha3_0_3(stage2_reg[0][3], stage2_reg[1][3], stage3[0][3], stage3[1][4]);
    half_a ha3_0_4(stage2_reg[0][4], stage2_reg[1][4], stage3[0][4], stage3[1][5]);
    half_a ha3_0_5(stage2_reg[0][5], stage2_reg[1][5], stage3[0][5], stage3[1][6]);
    half_a ha3_0_6(stage2_reg[0][6], stage2_reg[1][6], stage3[0][6], stage3[1][7]);
    half_a ha3_0_7(stage2_reg[0][7], stage2_reg[1][7], stage3[0][7], stage3[1][8]);
    full_a fa3_0_8(stage2_reg[0][8],stage2_reg[1][8],stage2_reg[2][8],stage3[0][8], stage3[1][9]);
    full_a fa3_0_9(stage2_reg[0][9],stage2_reg[1][9],stage2_reg[2][9],stage3[0][9], stage3[1][10]);
    full_a fa3_0_10(stage2_reg[0][10],stage2_reg[1][10],stage2_reg[2][10],stage3[0][10], stage3[1][11]);
    assign cout3[0][10] = 0;

    genvar s;
    generate
        for( s= 11;s<=22;s++) begin : compressor3_row_1
            comp4_2 row3_1(stage2_reg[0][s],stage2_reg[1][s],stage2_reg[2][s],stage2_reg[3][s],cout3[0][s-1],stage3[0][s],stage3[1][s+1],cout3[0][s]);
        end
    endgenerate

    comp4_2 comp3_1_23(1'b0,stage2_reg[1][23],stage2_reg[2][23],stage2_reg[3][23],cout3[0][22],stage3[0][23],stage3[1][24],cout3[0][23]);
    full_a fa3_2_24(stage2_reg[2][24],stage2_reg[3][24],cout3[0][23],stage3[0][24], stage3[1][25]);
    half_a ha3_2_25(stage2_reg[2][25], stage2_reg[3][25], stage3[0][25], stage3[1][26]);
    half_a ha3_2_26(stage2_reg[2][26], stage2_reg[3][26], stage3[0][26], stage3[1][27]);
    half_a ha3_2_27(stage2_reg[2][27], stage2_reg[3][27], stage3[0][27], stage3[1][28]);
    half_a ha3_2_28(stage2_reg[2][28], stage2_reg[3][28], stage3[0][28], stage3[1][29]);
    half_a ha3_2_29(stage2_reg[2][29], stage2_reg[3][29], stage3[0][29], stage3[1][30]);
    half_a ha3_2_30(stage2_reg[2][30], stage2_reg[3][30], stage3[0][30], stage3[1][31]);

    assign stage3[0][31] = stage2_reg[3][31];
    always_ff @( posedge clk ) begin
        stage3_reg <= stage3;
    end
//---------------------------------------------------------------------------------------------------------------------------//


logic final_cout;
logic [31:0] result;
brent_kung_adder_32 final_adder(stage3_reg[0],stage3_reg[1],0,result,final_cout);

always_ff @(posedge clk) begin
    P <= result;
end

endmodule