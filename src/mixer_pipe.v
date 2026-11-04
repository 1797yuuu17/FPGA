// Pipelined adaptation of MIT fpga-verilog-synth mixer; see THIRD_PARTY.md.
module mixer_pipe(input clk,input rst,
 input signed [15:0] s0,input [15:0] e0,input signed [15:0] s1,input [15:0] e1,
 input signed [15:0] s2,input [15:0] e2,input signed [15:0] s3,input [15:0] e3,
 output reg signed [15:0] pcm);
 reg signed [32:0] p0,p1,p2,p3;
 reg signed [15:0] a0,a1,a2,a3;reg [15:0] g0,g1,g2,g3;
 reg signed [17:0] sum;
 wire signed [15:0] v0=p0[31:16],v1=p1[31:16],v2=p2[31:16],v3=p3[31:16];
 always @(posedge clk)begin
 if(rst)begin a0<=0;a1<=0;a2<=0;a3<=0;g0<=0;g1<=0;g2<=0;g3<=0;p0<=0;p1<=0;p2<=0;p3<=0;sum<=0;pcm<=0;end
 else begin
 a0<=s0;a1<=s1;a2<=s2;a3<=s3;g0<=e0;g1<=e1;g2<=e2;g3<=e3;
 p0<=a0*$signed({1'b0,g0});p1<=a1*$signed({1'b0,g1});
 p2<=a2*$signed({1'b0,g2});p3<=a3*$signed({1'b0,g3});
 sum<={{2{v0[15]}},v0}+{{2{v1[15]}},v1}+{{2{v2[15]}},v2}+{{2{v3[15]}},v3};
 pcm<=sum>>>2;
 end end
endmodule
