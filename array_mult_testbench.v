`timescale 1ns / 1ps

module tb_array_multiplier_16bit_30;

    reg  [15:0] A;
    reg  [15:0] B;
    wire [31:0] P;

    array_multiplier_16bit uut (
        .A(A),
        .B(B),
        .P(P)
    );

    integer idx;
    integer errors;
    integer passes;

    task check_result(input [15:0] a_in, input [15:0] b_in);
        reg [31:0] expected;
        begin
            expected = a_in * b_in;
            #5; 
            if (P !== expected) begin
                $display("%0t: MISMATCH #%0d: A=0x%04h (%0d), B=0x%04h (%0d) -> DUT=0x%08h (%0d), Expected=0x%08h (%0d)",
                         $time, idx, a_in, a_in, b_in, b_in, P, P, expected, expected);
                errors = errors + 1;
            end else begin
                $display("%0t: PASS     #%0d: A=0x%04h (%0d), B=0x%04h (%0d) -> Product=0x%08h (%0d)",
                         $time, idx, a_in, a_in, b_in, b_in, P, P);
                passes = passes + 1;
            end
        end
    endtask

    initial begin
       
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_array_multiplier_16bit_30);

        $display("------ Starting 16x16 Array Multiplier 30-case Testbench ------");

        errors = 0;
        passes = 0;
        idx = 0;
       
        idx = idx + 1; A = 16'h0000; B = 16'h0000; check_result(A, B); // 0 * 0
        idx = idx + 1; A = 16'h0001; B = 16'h0001; check_result(A, B); // 1 * 1
        idx = idx + 1; A = 16'hFFFF; B = 16'h0001; check_result(A, B); // max * 1
        idx = idx + 1; A = 16'hFFFF; B = 16'hFFFF; check_result(A, B); // max * max
        idx = idx + 1; A = 16'h8000; B = 16'h0002; check_result(A, B); // high bit * 2
        idx = idx + 1; A = 16'h7FFF; B = 16'h0002; check_result(A, B); // large * 2
        idx = idx + 1; A = 16'h00FF; B = 16'h0002; check_result(A, B); // 255 * 2
        idx = idx + 1; A = 16'h0F0F; B = 16'hF0F0; check_result(A, B); // pattern
        idx = idx + 1; A = 16'hAAAA; B = 16'h5555; check_result(A, B); // alternate bits
        idx = idx + 1; A = 16'h1234; B = 16'h5678; check_result(A, B); // arbitrary
        
        idx = idx + 1; A = 16'h0002; B = 16'h8000; check_result(A, B);
        idx = idx + 1; A = 16'h00AA; B = 16'h00BB; check_result(A, B);
        idx = idx + 1; A = 16'h0100; B = 16'h0100; check_result(A, B);
        idx = idx + 1; A = 16'h00FF; B = 16'h00FF; check_result(A, B);
        idx = idx + 1; A = 16'h0FFF; B = 16'h0003; check_result(A, B);
        idx = idx + 1; A = 16'hF000; B = 16'h0004; check_result(A, B);
        idx = idx + 1; A = 16'h00C0; B = 16'h00C0; check_result(A, B);
        idx = idx + 1; A = 16'h5555; B = 16'h3333; check_result(A, B);
        idx = idx + 1; A = 16'h8001; B = 16'h0001; check_result(A, B);
        idx = idx + 1; A = 16'h00FE; B = 16'h00FF; check_result(A, B);

        idx = idx + 1; A = 16'hA5A5; B = 16'h5A5A; check_result(A, B);
        idx = idx + 1; A = 16'h0A0A; B = 16'h0B0B; check_result(A, B);
        idx = idx + 1; A = 16'h3333; B = 16'h7777; check_result(A, B);
        idx = idx + 1; A = 16'h2468; B = 16'h1357; check_result(A, B);
        idx = idx + 1; A = 16'h8000; B = 16'hFFFF; check_result(A, B);
        idx = idx + 1; A = 16'h7F7F; B = 16'h0101; check_result(A, B);
        idx = idx + 1; A = 16'h00AB; B = 16'hCD00; check_result(A, B);
        idx = idx + 1; A = 16'h0F00; B = 16'h00F0; check_result(A, B);
        idx = idx + 1; A = 16'h3C3C; B = 16'hC3C3; check_result(A, B);
        idx = idx + 1; A = 16'h1357; B = 16'h2468; check_result(A, B);

        $display("------ 16x16 Array Multiplier Test Summary ------");
        $display("Total tests : %0d", passes + errors);
        $display("Passed      : %0d", passes);
        $display("Failed      : %0d", errors);

        $finish;
    end

endmodule
