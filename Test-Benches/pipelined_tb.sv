`timescale 1ns / 1ps

module wallace_mult_tb;

    localparam CLK_PERIOD = 10; 
    localparam PIPELINE_STAGES = 5;
    logic           clk;
    logic [15:0]    A;
    logic [15:0]    B;
    logic [31:0]    P; 
    logic [31:0]    P_expected;
    logic [15:0]    A_pipe [0:PIPELINE_STAGES-1];
    logic [15:0]    B_pipe [0:PIPELINE_STAGES-1];
    logic [31:0]    P_expected_pipe [0:PIPELINE_STAGES-1];
    int             cycle_count = 0;
    wallace_mult dut (
        .clk(clk),
        .A(A),
        .B(B),
        .P(P)
    );
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end
    assign P_expected = A * B;

    //    This pipeline stores the inputs (A, B) and the expected result (P_expected)
    //    to align them with the DUT's 5-stage pipelined output.
    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        A_pipe[0] <= A;
        B_pipe[0] <= B;
        P_expected_pipe[0] <= P_expected;
        for (int i = 1; i < PIPELINE_STAGES; i = i + 1) begin
            A_pipe[i] <= A_pipe[i-1];
            B_pipe[i] <= B_pipe[i-1];
            P_expected_pipe[i] <= P_expected_pipe[i-1];
        end
    end
    logic [15:0] A_delayed;
    logic [15:0] B_delayed;
    logic [31:0] P_expected_delayed;

    assign A_delayed = A_pipe[PIPELINE_STAGES-1];
    assign B_delayed = B_pipe[PIPELINE_STAGES-1];
    assign P_expected_delayed = P_expected_pipe[PIPELINE_STAGES-1];
    always @(posedge clk) begin
        if (cycle_count > PIPELINE_STAGES) begin
            if (P !== P_expected_delayed) begin
                $error("MISMATCH! (Inputs 5 cycles ago: A=0x%h, B=0x%h) | DUT Result: 0x%h | Expected Result: 0x%h",
                       A_delayed, B_delayed, P, P_expected_delayed);
            end else begin
                $display("PASS. (Inputs 5 cycles ago: A=0x%h, B=0x%h) | Result: 0x%h",
                         A_delayed, B_delayed, P);
            end
        end
    end
    initial begin
        $display("Starting testbench...");
        $dumpfile("waveform.vcd");
        $dumpvars(0, wallace_mult_tb);
        A = 0;
        B = 0;
        @(posedge clk);
        // --- Test Case 2: One zero ---
        A = 1234;
        B = 0;
        @(posedge clk);

        // --- Test Case 3: Other zero ---
        A = 0;
        B = 5678;
        @(posedge clk);

        // --- Test Case 4: Max unsigned values ---
        A = 16'hFFFF;
        B = 16'hFFFF;
        @(posedge clk); 

        // --- Test Case 6: Random values ---
        $display("--- Starting 20 random tests ---");
        for (int i = 0; i < 20; i = i + 1) begin
            A = $urandom();
            B = $urandom();
            @(posedge clk);
        end
        $display("--- Finished random tests ---");

        // Wait for the pipeline to flush
        repeat (PIPELINE_STAGES + 2) @(posedge clk);

        $display("Test complete.");
        $finish;
    end

endmodule