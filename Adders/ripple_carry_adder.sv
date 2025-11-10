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
