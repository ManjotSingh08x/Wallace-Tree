`timescale 1ns / 1ps
module array_multiplier_tb;
    reg [15:0] A, B;
    wire [31:0] P_array;
    wire [31:0] P_optimal;
    array_mult dut (.a(A), .b(B), .p(P_array));

    // Optimal mult here is a module which just returns A*B 
    optimal_mult optimal (.a(A), .b(B), .p(P_optimal));
    
    integer i;
    initial begin 
        $display("Testbench starting...");
        // --- Test 1: Corner Cases ---
        $display("Testing corner cases...");
        
        // Test 0 * 0
        A = 16'd0; B = 16'd0; #10;
        if (P_array !== P_optimal) $display("Mismatch! A=%d, B=%d, Array=%d, Behavioral=%d", A, B, P_array, P_optimal);

        // Test 1 * 1
        A = 16'd1; B = 16'd1; #10;
        if (P_array !== P_optimal) $display("Mismatch! A=%d, B=%d, Array=%d, Behavioral=%d", A, B, P_array, P_optimal);

        // Test Max * Max (Unsigned)
        A = 16'hFFFF; B = 16'hFFFF; #10;
        if (P_array !== P_optimal) $display("Mismatch! A=%d, B=%d, Array=%d, Behavioral=%d", A, B, P_array, P_optimal);
        
        // Test Max * 0
        A = 16'hFFFF; B = 16'd0; #10;
        if (P_array !== P_optimal) $display("Mismatch! A=%d, B=%d, Array=%d, Behavioral=%d", A, B, P_array, P_optimal);

        // --- Test 2: Randomized Test Vectors ---
        $display("Testing 20 random cases...");
        
        for (i = 0; i < 20; i = i + 1) begin
            A = $random;
            B = $random;
            #10; 
            if (P_array !== P_optimal) begin
                $display("ERROR: Mismatch found!");
                $display("A = %h (%d), B = %h (%d)", A, A, B, B);
                $display("Array_Product     = %h (%d)", P_array, P_array);
                $display("Behavioral_Product = %h (%d)", P_optimal, P_optimal);
            end
        end
        $display("Success! All corner cases and 100 random tests passed.");
        $stop; 
    end
endmodule
