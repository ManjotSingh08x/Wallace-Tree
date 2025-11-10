module full_a (
    input  logic a, b, cin,
    output logic sum, carry
);
    assign sum   = a ^ b ^ cin;
    assign carry = (a & b) | (b & cin) | (cin & a);
endmodule