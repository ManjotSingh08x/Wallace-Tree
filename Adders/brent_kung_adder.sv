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