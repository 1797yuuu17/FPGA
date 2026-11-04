`timescale 1ns/1ps
module tb_buzzer;
 reg clk=0;always #10 clk=~clk;
 reg rst=1;reg [6:0] keys=0;wire beep;
 buzzer_test dut(clk,rst,keys,beep);
 task check;input c;input [511:0] msg;begin if(!c)begin $display("FAIL %s",msg);$fatal(1);end end endtask
 task frequency;input real hz;time t0,t1;real measured;begin
 @(posedge beep);t0=$time;repeat(8)@(posedge beep);t1=$time;
 measured=8.0e9/(t1-t0);check(measured>hz*0.995 && measured<hz*1.005,"buzzer frequency within 0.5 percent");
 $display("Measured %0.3f Hz expected %0.3f Hz",measured,hz);
 end endtask
 task duty;input real target;time a,b,c;real measured;begin
 @(posedge beep);a=$time;@(negedge beep);b=$time;@(posedge beep);c=$time;
 measured=1.0*(b-a)/(c-a);
 check(measured>target-0.005 && measured<target+0.005,"per-note buzzer duty compensation");
 $display("Measured duty %0.3f expected %0.3f",measured,target);
 end endtask
 integer n;
 initial begin
 repeat(5)@(negedge clk);rst=0;repeat(100)@(negedge clk);check(beep===0,"no keys silent");
 keys=1;frequency(2093.0045);duty(0.5);
 keys=7'b0000100;frequency(2637.0205);duty(0.125);
 keys=7'b0001000;frequency(2793.8259);duty(0.125);
 keys=7'b0100000;frequency(3520.0);duty(0.5);
 keys=7'b0100001;frequency(2093.0045);
 keys=0;repeat(5)@(negedge clk);check(beep===0,"release silent");
 keys=7'b1000000;repeat(10000)@(negedge clk);rst=1;repeat(5)@(negedge clk);check(beep===0,"reset silent");
 $display("PASS tb_buzzer");$finish;
 end
 initial begin #30000000;$fatal(1,"buzzer test timeout");end
endmodule
