`timescale 1ns/1ps
module tb_math;
 reg clk=0;always #5 clk=~clk;
 reg rst=1; wire signed [15:0] piped;
 reg signed [15:0] x0,x1,x2,x3;reg [15:0] e0,e1,e2,e3;
 wire signed [15:0] mixed;
 mixer m(x0,e0,x1,e1,x2,e2,x3,e3,mixed);
 mixer_pipe mp(clk,rst,x0,e0,x1,e1,x2,e2,x3,e3,piped);
 reg [31:0] phase;reg [1:0] shape;wire signed [15:0] val;
 waveform w(phase,shape,val);
 task check;input c;input [511:0] msg;begin if(!c)begin $display("FAIL %s",msg);$fatal(1);end end endtask
 integer i,expected,total;integer seed=813;
 function integer scale;input integer x,e;begin scale=(x*e)>>>16;end endfunction
 initial begin
 #11;rst=0;
 x0=32767;x1=32767;x2=32767;x3=32767;e0=65535;e1=65535;e2=65535;e3=65535;#1;check(mixed==32766,"positive full scale");
 x0=-32768;x1=-32768;x2=-32768;x3=-32768;#1;check(mixed==-32768,"negative full scale");
 e0=0;e1=0;e2=0;e3=0;#1;check(mixed==0,"zero envelope");
 for(i=0;i<2000;i=i+1)begin
 x0=$random(seed);x1=$random(seed);x2=$random(seed);x3=$random(seed);
 e0=$random(seed);e1=$random(seed);e2=$random(seed);e3=$random(seed);#1;
 total=scale(x0,e0)+scale(x1,e1)+scale(x2,e2)+scale(x3,e3);expected=total>>>2;
 check(mixed==expected,"random signed mixer reference");
 repeat(4)@(negedge clk);check(piped==expected,"pipelined mixer matches signed reference");end
 shape=0;phase=0;#1;check(val==0,"sine zero");phase=32'h40000000;#1;check(val==30000,"sine peak");phase=32'hc0000000;#1;check(val==-30000,"sine trough");
 shape=1;phase=0;#1;check(val==30000,"square positive");phase=32'h80000000;#1;check(val==-30000,"square negative");
 shape=2;phase=0;#1;check(val==-32768,"triangle low");phase=32'h80000000;#1;check(val==32767,"triangle high");
 $display("PASS tb_math");$finish;
 end
endmodule
