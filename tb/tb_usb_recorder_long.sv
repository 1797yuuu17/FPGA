`timescale 1ns/1ps
module tb_usb_recorder_long;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,ms=0,rcmd=0,pcmd=0,clear=0;reg [11:0] source=0;
 wire [11:0] replay;wire rec,play,valid,limited;
 event_recorder_usb u(clk,rst,ms,rcmd,pcmd,clear,source,replay,rec,play,valid,limited);
 task cycles;input integer n;begin repeat(n)@(negedge clk);end endtask
 task step;begin cycles(4);ms=1;cycles(1);ms=0;cycles(4);end endtask
 task rc;begin rcmd=1;cycles(1);rcmd=0;cycles(4);end endtask
 task pc;begin pcmd=1;cycles(1);pcmd=0;cycles(4);end endtask
 integer i;
 initial begin cycles(5);rst=0;cycles(4);rc();
 for(i=0;i<1100;i=i+1)begin source=(i%2)?1:2;step();if(!rec)$fatal(1,"event capacity truncated");end
 rc();pc();for(i=0;i<1100;i=i+1)begin step();if(replay!=((i%2)?1:2))$fatal(1,"event memory address wrap at %d",i);end
 step();step();if(play || replay!=0)$fatal(1,"event clip end release");
 clear=1;cycles(1);clear=0;cycles(4);rc();source=8;
 repeat(119999)step();if(!rec || limited)$fatal(1,"120s counter wrapped or stopped early");
 step();if(rec || !valid || !limited)$fatal(1,"120s limit failed");
 rc();if(rec || !valid)$fatal(1,"acknowledge must preserve 120s clip");pc();
 step();if(replay!=8)$fatal(1,"120s first event");repeat(119999)step();
 if(!play)$fatal(1,"120s playback ended early");step();step();if(play || replay!=0)$fatal(1,"120s end must release");
 $display("PASS tb_usb_recorder_long: 1100 events and full120000ms boundary");$finish;end
 initial begin #1000000000;$fatal(1,"timeout");end
endmodule
