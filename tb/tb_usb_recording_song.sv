`timescale 1ns/1ps
module tb_usb_recording_song;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,ms=0,page=1;reg [6:0] keys=0;
 wire [6:0] notes;wire rec,play,valid,limited;
 performance_ctrl_usb u(.clk(clk),.rst(rst),.ms_tick(ms),.keys(keys),.control_page(page),.timbre(2'b0),.long_env(1'b0),.notes(notes),.recording(rec),.playing(play),.has_clip(valid),.limited(limited));
 task cycles;input integer n;begin repeat(n)@(negedge clk);end endtask
 task step;begin cycles(4);ms=1;cycles(1);ms=0;cycles(4);end endtask
 task command;input [6:0] k;begin keys=0;cycles(5);keys=k;cycles(5);keys=0;cycles(5);end endtask
 function [6:0] song;input integer n;integer row,col;begin row=n/7;col=n%7;
 if(row==0 || row==4)case(col)0,1:song=1;2,3:song=16;4,5:song=32;6:song=16;endcase
 else if(row==1 || row==5)case(col)0,1:song=8;2,3:song=4;4,5:song=2;6:song=1;endcase
 else case(col)0,1:song=16;2,3:song=8;4,5:song=4;6:song=2;endcase
 end endfunction
 integer i,j,guard;reg [6:0] previous;
 initial begin cycles(5);rst=0;cycles(8);command(16);if(!rec)$fatal(1,"record start");
 step();page=0;cycles(8);
 for(i=0;i<42;i=i+1)begin keys=song(i);if(i%7==6)repeat(1900)step();else repeat(900)step();keys=0;repeat(100)step();
 if(!rec || limited)$fatal(1,"48-second song must not hit old 30-second limit");end
 page=1;cycles(8);command(16);if(rec || !valid)$fatal(1,"manual save song");
 command(16);if(rec || !valid)$fatal(1,"accidental second K5 must preserve song");
 command(32);if(!play)$fatal(1,"play saved song");previous=0;j=0;guard=0;
 while(play && guard<50000)begin step();guard=guard+1;
 if(notes!=0 && notes!=previous)begin if(j>=42 || notes!=song(j))$fatal(1,"song replay mismatch at %d",j);j=j+1;end
 previous=notes;end
 if(play || j!=42 || notes!=0)$fatal(1,"song incomplete or stuck %d",j);
 $display("PASS tb_usb_recording_song: 48-second Little Star, all42 notes replayed");$finish;end
 initial begin #1000000000;$fatal(1,"timeout");end
endmodule
