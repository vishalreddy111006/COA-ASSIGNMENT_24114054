`timescale 1ns / 1ps

module fulladder(input wire a,b,c, output wire sum,carry);
    assign sum = a ^ b ^ c;
    assign carry = (a & b) | (b & c) | (c & a);
endmodule

module compressor_7_to_3(
    input  wire w0,w1,w2,w3,w4,w5,w6,
    output wire sum, c0, c1
);
    wire s1,s2,s3,s4,d1,d2,d3,d4;

    fulladder fa1(.a(w0), .b(w1), .c(w2), .sum(s1), .carry(d1));
    fulladder fa2(.a(w3), .b(w4), .c(w5), .sum(s2), .carry(d2));
    fulladder fa3(.a(s1), .b(s2), .c(w6), .sum(s3), .carry(d3));
    fulladder fa4(.a(d1), .b(d2), .c(d3), .sum(s4), .carry(d4));

    assign sum = s3;
    assign c0  = s4;
    assign c1  = d4;
endmodule
module array_7_to_3_compressor(
    input  wire [31:0] p0,p1,p2,p3,p4,p5,p6,
    output wire [31:0] psum, pc0, pc1
);
    genvar j;
    generate
        for(j=0; j<32; j=j+1) begin
            compressor_7_to_3 C(
                p0[j], p1[j], p2[j], p3[j], p4[j], p5[j], p6[j],
                psum[j], pc0[j], pc1[j]
            );
        end
    endgenerate
endmodule

module array_3_to_2_compressor(
    input  wire [31:0] a,b,c,
    output wire [31:0] sum, carry
);
    assign sum   = a ^ b ^ c;
    assign carry = ((a & b) | (b & c) | (c & a)) << 1;
endmodule

module han_carlson_adder(
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] sum,
    output wire carry_out
);
    wire [31:0] g, p;
    assign g = a & b;
    assign p = a ^ b;

    wire [31:0] g1, p1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    genvar i;
    generate
        for(i=1;i<32;i=i+1) begin
            assign g1[i] = g[i] | (p[i] & g[i-1]);
            assign p1[i] = p[i] & p[i-1];
        end
    endgenerate

    wire [31:0] g2, p2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    generate
        for(i=2;i<32;i=i+1) begin
            assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
            assign p2[i] = p1[i] & p1[i-2];
        end
    endgenerate

    wire [31:0] g3, p3;
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    generate
        for(i=4;i<32;i=i+1) begin
            assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
            assign p3[i] = p2[i] & p2[i-4];
        end
    endgenerate

    wire [31:0] g4, p4;
    assign g4[0] = g3[0];
    assign p4[0] = p3[0];
    assign g4[1] = g3[1];
    assign p4[1] = p3[1];
    assign g4[2] = g3[2];
    assign p4[2] = p3[2];
    assign g4[3] = g3[3];
    assign p4[3] = p3[3];
    assign g4[4] = g3[4];
    assign p4[4] = p3[4];
    assign g4[5] = g3[5];
    assign p4[5] = p3[5];
    assign g4[6] = g3[6];
    assign p4[6] = p3[6];
    assign g4[7] = g3[7];
    assign p4[7] = p3[7];
    generate
        for(i=8;i<32;i=i+1) begin
            assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
            assign p4[i] = p3[i] & p3[i-8];
        end
    endgenerate

    wire [31:0] g5, p5;
    assign g5[0]  = g4[0];  assign p5[0]  = p4[0];
    assign g5[1]  = g4[1];  assign p5[1]  = p4[1];
    assign g5[2]  = g4[2];  assign p5[2]  = p4[2];
    assign g5[3]  = g4[3];  assign p5[3]  = p4[3];
    assign g5[4]  = g4[4];  assign p5[4]  = p4[4];
    assign g5[5]  = g4[5];  assign p5[5]  = p4[5];
    assign g5[6]  = g4[6];  assign p5[6]  = p4[6];
    assign g5[7]  = g4[7];  assign p5[7]  = p4[7];
    assign g5[8]  = g4[8];  assign p5[8]  = p4[8];
    assign g5[9]  = g4[9];  assign p5[9]  = p4[9];
    assign g5[10] = g4[10]; assign p5[10] = p4[10];
    assign g5[11] = g4[11]; assign p5[11] = p4[11];
    assign g5[12] = g4[12]; assign p5[12] = p4[12];
    assign g5[13] = g4[13]; assign p5[13] = p4[13];
    assign g5[14] = g4[14]; assign p5[14] = p4[14];
    assign g5[15] = g4[15]; assign p5[15] = p4[15];
    generate
        for(i=16;i<32;i=i+1) begin
            assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
            assign p5[i] = p4[i] & p4[i-16];
        end
    endgenerate

    wire [31:0] carry_in; 

    assign carry_in[0] = 1'b0;
    assign carry_in[1]  = g[0];
    assign carry_in[2]  = g1[1];
    assign carry_in[3]  = g2[2];
    assign carry_in[4]  = g3[3];

    generate
        for(i=5;i<32;i=i+1) begin
            assign carry_in[i] = g5[i-1];
        end
    endgenerate

    generate
        for(i=0;i<32;i=i+1) begin
            assign sum[i] = p[i] ^ carry_in[i];
        end
    endgenerate

    assign carry_out = g5[31];
endmodule


module piped_wallace_mult(
    input wire clock, reset,
    input wire [15:0] x,y,
    output reg [31:0] prod
);

    genvar i,j;
    wire [31:0] pp[0:15];

    generate
        for(i=0; i<16; i=i+1) begin : PP_GEN
            for(j=0; j<32; j=j+1) begin : COL
                assign pp[i][j] = (j>=i && j<i+16) ? (x[j-i] & y[i]) : 1'b0;
            end
        end
    endgenerate

    wire [31:0] s0,s1,c0_0,c1_0,c02_0,c12_0;

    array_7_to_3_compressor A0(pp[0],pp[1],pp[2],pp[3],pp[4],pp[5],pp[6], s0, c0_0, c02_0);
    array_7_to_3_compressor A1(pp[7],pp[8],pp[9],pp[10],pp[11],pp[12],pp[13], s1, c1_0, c12_0);

    wire [31:0] c0  = c0_0  << 1;
    wire [31:0] c1  = c1_0  << 1;
    wire [31:0] c02 = c02_0 << 2;
    wire [31:0] c12 = c12_0 << 2;

    reg [31:0] rs0,rs1,rc0,rc1,rc02,rc12, rpp14,rpp15;

    always @(posedge clock or posedge reset)
        if(reset) begin
            rs0<=0; rs1<=0; rc0<=0; rc1<=0; rc02<=0; rc12<=0;
            rpp14<=0; rpp15<=0;
        end else begin
            rs0<=s0; rs1<=s1; rc0<=c0; rc1<=c1; rc02<=c02; rc12<=c12;
            rpp14<=pp[14]; rpp15<=pp[15];
        end

    wire [31:0] sum1,carry_1,carry_2;

    array_7_to_3_compressor A2(
        rs0,rs1,rc0,rc1,rc02,rc12,rpp14,
        sum1, carry_1, carry_2
    );

    wire [31:0] carry1 = carry_1 << 1;
    wire [31:0] carry2 = carry_2 << 2;

    reg [31:0] rsum1,rcarry1,rcarry2,rlast;

    always @(posedge clock or posedge reset)
        if(reset) begin
            rsum1<=0; rcarry1<=0; rcarry2<=0; rlast<=0;
        end else begin
            rsum1<=sum1; rcarry1<=carry1; rcarry2<=carry2;
            rlast<=rpp15;
        end

    wire [31:0] psum_1, pcarry_1, final_sum_pre, final_carry_pre;

    array_3_to_2_compressor C0(rsum1, rcarry1, rcarry2, psum_1, pcarry_1);
    array_3_to_2_compressor C1(rlast, psum_1, pcarry_1, final_sum_pre, final_carry_pre);

    reg [31:0] rsum, rcarry;

    always @(posedge clock or posedge reset)
        if(reset) begin
            rsum<=0; rcarry<=0;
        end else begin
            rsum<=final_sum_pre;
            rcarry<=final_carry_pre;
        end

    wire [31:0] final_sum;
    wire cout;

    han_carlson_adder HC(rsum, rcarry, final_sum, cout);

    always @(posedge clock or posedge reset)
        if(reset)
            prod <= 0;
        else
            prod <= final_sum;

endmodule
