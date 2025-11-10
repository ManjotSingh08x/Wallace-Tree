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