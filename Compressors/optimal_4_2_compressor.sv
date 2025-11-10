module comp4_2 (
    input  logic i0, i1, i2, i3, cin, 
    output logic sum, carry, cout     
);
    logic a, b, c;
    assign a = i0 ^ i1;
    assign b = i2 ^ i3;
    assign c = a ^ b; 
    assign cout = a ? i2 : i0;
    assign sum = cin ^ c;
    assign carry = c ? cin : i3;
endmodule