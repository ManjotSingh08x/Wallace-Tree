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