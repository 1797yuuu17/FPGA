`timescale 1ns/1ps
module tb_usb_recorder;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,ms=0,rcmd=0,pcmd=0,clear=0;reg [11:0] source=0;
 wire [11:0] replay;wire rec,play,valid,limited;
 event_recorder_usb #(.MAX_EVENTS(4),.MAX_MS(12)) u(clk,rst,ms,rcmd,pcmd,clear,source,replay,rec,play,valid,limited);
 task cycles;input integer n;begin repeat(n)@(negedge clk);end endtask
 task step;begin cycles(4);ms=1;cycles(1);ms=0;cycles(4);end endtask
 task rc;begin rcmd=1;cycles(1);rcmd=0;cycles(4);end endtask
 task pc;begin pcmd=1;cycles(1);pcmd=0;cycles(4);end endtask
 initial begin
 cycles(5);rst=0;cycles(4);rc();source=1;repeat(12)step();
 if(rec || !valid || !limited)$fatal(1,"time limit must save clip");
 rc();if(rec || !valid || limited)$fatal(1,"K5 after auto-stop must acknowledge, not overwrite saved clip");
 pc();step();if(!play || replay!=1)$fatal(1,"saved note must replay after K5 acknowledgement");
 pc();if(play)$fatal(1,"K6 must stop playback");
 clear=1;cycles(1);clear=0;cycles(4);rc();source=4;step();source=0;step();
 pc();if(rec || !play || !valid)$fatal(1,"K6 during recording must stop and start replay in one press");
 step();if(replay!=4)$fatal(1,"direct replay lost first event");
 step();step();step();if(play || replay!=0)$fatal(1,"direct replay must finish released");
 rc();if(rec || !valid)$fatal(1,"saved clip protected against accidental K5");
 clear=1;cycles(1);clear=0;cycles(4);rc();source=1;step();source=2;step();source=4;step();source=8;step();
 if(rec || !valid || !limited)$fatal(1,"event limit must save clip");
 rc();pc();step();if(replay!=1)$fatal(1,"capacity clip must survive K5 then K6");
 $display("PASS tb_usb_recorder");$finish;end
 initial begin #10000000;$fatal(1,"timeout");end
endmodule
