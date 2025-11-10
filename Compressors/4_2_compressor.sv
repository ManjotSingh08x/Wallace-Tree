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

