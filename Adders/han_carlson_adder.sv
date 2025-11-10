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