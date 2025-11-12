`timescale 1ns / 1ps

module ha_unit (
    input  a_in,
    input  b_in,
    output s_out,
    output c_out
);
    assign s_out = a_in ^ b_in;
    assign c_out = a_in & b_in;
endmodule

module fa_unit (
    input  x_in,
    input  y_in,
    input  z_in,
    output s_out,
    output c_out
);
    wire t1, c1, c2;
    ha_unit H1 (.a_in(x_in), .b_in(y_in), .s_out(t1), .c_out(c1));
    ha_unit H2 (.a_in(t1), .b_in(z_in), .s_out(s_out), .c_out(c2));
    assign c_out = c1 | c2;
endmodule

module matmul16x16 (
    input  [15:0] IN_A,
    input  [15:0] IN_B,
    output [31:0] OUT_P
);
    wire [15:0] pp_mat [15:0];
    genvar gi, gj;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : gen_pp_rows
            for (gj = 0; gj < 16; gj = gj + 1) begin : gen_pp_cols
                assign pp_mat[gi][gj] = IN_A[gj] & IN_B[gi];
            end
        end
    endgenerate

    wire [31:0] sum_row   [14:0];
    wire [32:0] carry_row [14:0];

    assign OUT_P[0] = pp_mat[0][0];

    ha_unit H0_1 (
        .a_in(pp_mat[0][1]),
        .b_in(pp_mat[1][0]),
        .s_out(sum_row[0][1]),
        .c_out(carry_row[0][2])
    );
    assign OUT_P[1] = sum_row[0][1];

    generate
        for (gj = 2; gj < 16; gj = gj + 1) begin : gen_row0_fas
            fa_unit F0 (
                .x_in(pp_mat[0][gj]),
                .y_in(pp_mat[1][gj-1]),
                .z_in(carry_row[0][gj]),
                .s_out(sum_row[0][gj]),
                .c_out(carry_row[0][gj+1])
            );
        end
    endgenerate

    ha_unit H0_16 (
        .a_in(pp_mat[1][15]),
        .b_in(carry_row[0][16]),
        .s_out(sum_row[0][16]),
        .c_out(carry_row[0][17])
    );

    assign sum_row[0][17] = carry_row[0][17];

    generate
        for (gj = 18; gj <= 31; gj = gj + 1) begin : gen_row0_zeroes
            assign sum_row[0][gj]     = 1'b0;
            assign carry_row[0][gj+1] = 1'b0;
        end
    endgenerate

    generate
        for (gi = 0; gi < 15; gi = gi + 1) begin : init_carry_blocks
            for (gj = 0; gj <= gi+1; gj = gj + 1) begin : init_carrs
                assign carry_row[gi][gj] = 1'b0;
            end
        end
    endgenerate

    generate
        for (gi = 1; gi < 15; gi = gi + 1) begin : gen_middle_rows
            ha_unit HRF (
                .a_in(sum_row[gi-1][gi+1]),
                .b_in(pp_mat[gi+1][0]),
                .s_out(sum_row[gi][gi+1]),
                .c_out(carry_row[gi][gi+2])
            );
            assign OUT_P[gi+1] = sum_row[gi][gi+1];

            for (gj = gi + 2; gj <= gi + 16; gj = gj + 1) begin : gen_mid_fas
                fa_unit FM (
                    .x_in(sum_row[gi-1][gj]),
                    .y_in(pp_mat[gi+1][gj - (gi+1)]),
                    .z_in(carry_row[gi][gj]),
                    .s_out(sum_row[gi][gj]),
                    .c_out(carry_row[gi][gj+1])
                );
            end

            for (gj = gi + 17; gj <= 31; gj = gj + 1) begin : gen_tail_has
                ha_unit HT (
                    .a_in(sum_row[gi-1][gj]),
                    .b_in(carry_row[gi][gj]),
                    .s_out(sum_row[gi][gj]),
                    .c_out(carry_row[gi][gj+1])
                );
            end
        end
    endgenerate

    generate
        for (gj = 16; gj <= 31; gj = gj + 1) begin : gen_high_assign
            assign OUT_P[gj] = sum_row[14][gj];
        end
    endgenerate

endmodule

module tb_matmul16x16_30;

    reg  [15:0] A;
    reg  [15:0] B;
    wire [31:0] P;

    matmul16x16 uut (
        .IN_A(A),
        .IN_B(B),
        .OUT_P(P)
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
        $dumpvars(0, tb_matmul16x16_30);

        errors = 0;
        passes = 0;
        idx = 0;

        idx = idx + 1; A = 16'h0000; B = 16'h0000; check_result(A, B);
        idx = idx + 1; A = 16'h0001; B = 16'h0001; check_result(A, B);
        idx = idx + 1; A = 16'hFFFF; B = 16'h0001; check_result(A, B);
        idx = idx + 1; A = 16'hFFFF; B = 16'hFFFF; check_result(A, B);
        idx = idx + 1; A = 16'h8000; B = 16'h0002; check_result(A, B);
        idx = idx + 1; A = 16'h7FFF; B = 16'h0002; check_result(A, B);
        idx = idx + 1; A = 16'h00FF; B = 16'h0002; check_result(A, B);
        idx = idx + 1; A = 16'h0F0F; B = 16'hF0F0; check_result(A, B);
        idx = idx + 1; A = 16'hAAAA; B = 16'h5555; check_result(A, B);
        idx = idx + 1; A = 16'h1234; B = 16'h5678; check_result(A, B);

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

        $display("Total tests : %0d", passes + errors);
        $display("Passed      : %0d", passes);
        $display("Failed      : %0d", errors);

        $finish;
    end

endmodule
