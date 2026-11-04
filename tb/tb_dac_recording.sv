`timescale 1ns/1ps
module tb_dac_recording;
 reg clk=0;always #10 clk=~clk;
 reg [7:0] keys=255;reg [3:0] sw=0;
 wire [7:0] led,seg;wire [3:0] dig;wire [9:0] data;
 wire dc,a,b,c,d,beep;
 top_dac #(.DEBOUNCE_CYCLES(8),.SAMPLE_DIV(16),.MS_DIV(1600)) dut(clk,keys,sw,led,seg,dig,data,dc,a,b,c,d,beep);
 task check;input cond;input [511:0] msg;begin if(!cond)begin $display("FAIL %s",msg);$fatal(1);end end endtask
 task cycles;input integer n;begin repeat(n)@(negedge clk);end endtask
 task press;input integer k;begin keys=255^(1<<k);cycles(100);keys=255;cycles(100);end endtask
 time changed=0,rising=0,last_rise=0;reg monitor=0;integer changes=0;
 always @(data)if(monitor && !dut.rst)begin
   changed=$time;check(dc===0,"data update on falling phase");check($time-rising>=30,"hold window");
   if(dut.playing && data!=512)changes=changes+1;
 end
 always @(posedge dc)if(monitor && !dut.rst)begin
   rising=$time;check($time-changed>=30,"setup window");
   if(last_rise!=0)check($time-last_rise==80,"continuous 12.5MHz DAC clock");last_rise=$time;
 end
 initial begin
 cycles(300);monitor=1;sw=8;cycles(100);press(4);
 check(dut.recording,"K5 starts recording on control page");
 sw=0;cycles(100);keys=8'hf0;cycles(256000);
 check(dut.count==4,"recorded live chord uses four voices");keys=255;cycles(160000);
 sw=8;cycles(100);press(5);
 check(dut.playing && !dut.recording && dut.has_clip,"K6 stops saves and plays through DAC top");
 cycles(440000);check(!dut.playing && changes>100,"playback generated nonzero DAC output and ended");
 press(4);check(dut.has_clip && !dut.recording,"K5 preserves saved clip");
 press(5);check(dut.playing,"saved clip can play again");press(5);check(!dut.playing,"K6 stops playback");
 press(6);check(!dut.has_clip,"K7 clears clip");
 check(beep==0 && {a,b,c,d}==4'b1100,"safe unused outputs");
 $display("PASS tb_dac_recording");$finish;
 end
 initial begin #30000000;$fatal(1,"timeout");end
endmodule
