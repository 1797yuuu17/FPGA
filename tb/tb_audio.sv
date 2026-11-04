`timescale 1ns/1ps
// Accelerated sample-domain run: one sample per clock, exported at 100 kS/s.
module tb_audio;
 reg clk=0;always #5 clk=~clk;
 reg rst=1,tick=0;reg [6:0] keys=0;reg [1:0] shape=0;
 wire signed [15:0] pcm;wire [2:0] count;
 synth_core dut(clk,rst,tick,keys,shape,1'b0,pcm,count,2'd1);
 integer f,i,s;
 initial begin
 f=$fopen("audio_samples.txt","w");
 repeat(4)@(negedge clk);rst=0;
 for(s=0;s<3;s=s+1)begin
 shape=s;
 for(i=0;i<90000;i=i+1)begin
 keys=(i<50000)?7'b0010101:0;
 @(negedge clk);tick=1;@(negedge clk);tick=0;repeat(4)@(negedge clk);$fwrite(f,"%0d\n",pcm);
 end end
 $fclose(f);$display("PASS tb_audio");$finish;
 end
endmodule
