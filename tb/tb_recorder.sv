`timescale 1ns/1ps
module tb_recorder;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,ms=0,record_cmd=0,play_cmd=0,clear=0;reg [11:0] source=0;
 wire [11:0] result;wire rec,play,valid,limit;
 event_recorder #(.MAX_EVENTS(4),.MAX_MS(12)) dut(clk,rst,ms,record_cmd,play_cmd,clear,source,result,rec,play,valid,limit);
 task ck;input ok;input[511:0] msg;begin if(!ok)begin $display("FAIL %s",msg);$fatal(1);end end endtask
 task cycles;input integer n;begin repeat(n)@(negedge clk);end endtask
 task step;begin cycles(4);ms=1;cycles(1);ms=0;cycles(4);end endtask
 task rc;begin record_cmd=1;cycles(1);record_cmd=0;cycles(4);end endtask
 task pc;begin play_cmd=1;cycles(1);play_cmd=0;cycles(4);end endtask
 initial begin
 cycles(5);rst=0;cycles(4);pc();ck(!play,"empty play ignored");rc();
 source=1;step();source=2;step();source=4;step();source=8;step();
 ck(!rec && valid && limit,"event capacity stops recording");pc();
 step();ck(result==1,"first event at time zero");step();ck(result==2,"second timestamp");step();ck(result==4,"third timestamp");step();ck(result==8,"last capacity event retained");
 step();ck(!play && result[6:0]==0,"capacity clip ends with release");
 source=5;rc();repeat(12)step();ck(!rec && limit,"time limit stops unchanged note");
 pc();step();ck(result==5,"time limited held note");repeat(12)step();ck(!play && result[6:0]==0,"time limit playback releases");
 rc();step();pc();ck(!rec && !play,"record and play mutually exclusive");pc();ck(play,"second play command starts clip");
 clear=1;cycles(1);clear=0;cycles(4);ck(!play && !rec && !valid,"clear stops all modes");
 $display("PASS tb_recorder");$finish;
 end
 initial begin #10000000;$fatal(1,"timeout");end
endmodule
