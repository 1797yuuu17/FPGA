`timescale 1ns/1ps
module tb_pcm_decimator;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,v=0;reg signed[15:0] pcm=0;
 wire ov;wire signed[15:0] op;integer n,f,outputs=0;
 pcm_decimator u(clk,rst,v,pcm,ov,op);
 always @(posedge clk)if(ov)begin outputs=outputs+1;$fdisplay(f,"%0d",op);end
 initial begin f=$fopen("fir_samples.txt","w");repeat(5)@(negedge clk);rst=0;repeat(300)@(negedge clk);
 for(n=0;n<800;n=n+1)begin
 pcm=(n==0)?30000:(n<300)?0:12000;v=1;@(negedge clk);v=0;repeat(499)@(negedge clk);end
 repeat(210)@(negedge clk);
 if(outputs!=200 || op<11999 || op>12001)$fatal(1,"FIR cadence/DC failed %d %d",outputs,op);
 $fclose(f);$display("PASS tb_pcm_decimator");$finish;end
 initial begin #20000000;$fatal(1,"timeout");end
endmodule
