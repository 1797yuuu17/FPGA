`timescale 1ns/1ps
module tb_performance;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,ms=0,page=0;reg [6:0] keys=0;
 reg [1:0] timbre=0;reg env=0;
 wire [6:0] notes;wire [1:0] oct,shape,selected,speed;wire envelope,arp,rec,play,valid,limit;
 performance_ctrl #(.REC_MAX_MS(40)) dut(clk,rst,ms,keys,page,timbre,env,notes,oct,shape,envelope,selected,arp,speed,rec,play,valid,limit);
 task ck;input ok;input [511:0] msg;begin if(!ok)begin $display("FAIL %s",msg);$fatal(1);end end endtask
 task cycles;input integer n;begin repeat(n)@(negedge clk);end endtask
 task step;begin cycles(3);ms=1;cycles(1);ms=0;cycles(3);end endtask
 task command;input [6:0] k;begin keys=0;cycles(5);keys=k;cycles(5);keys=0;cycles(5);end endtask
 integer i;
 initial begin
 cycles(5);rst=0;cycles(5);keys=1;cycles(5);ck(notes==1 && oct==1,"normal play default octave");
 page=1;cycles(5);ck(notes==0,"enter control suppresses held notes");
 ck(selected==1,"held key cannot become octave command");keys=0;cycles(5);
 command(1);ck(selected==0 && notes==0,"octave down is silent command");
 command(1);ck(selected==0,"octave clamps low");command(2);command(2);ck(selected==2,"octave high");
 command(4);ck(arp,"arpeggiator enabled");command(8);ck(speed==2,"tempo cycles");
 page=0;cycles(5);keys=7'b0010101;cycles(5);ck(notes==1,"arpeggio starts lowest");
 repeat(63)step();ck(notes==0,"arpeggio gate gap");repeat(62)step();ck(notes==4,"arpeggio next held note");
 repeat(125)step();ck(notes==16,"arpeggio third note");repeat(125)step();ck(notes==1,"arpeggio wraps");
 keys=0;cycles(5);ck(notes==0,"arpeggio release");
 keys=4;cycles(5);ck(notes==4,"single key arpeggio onset");
 repeat(63)step();ck(notes==0,"single key arpeggio gap");repeat(62)step();ck(notes==4,"single key arpeggio retrigger");
 keys=5;cycles(5);ck(notes==1,"changed held set restarts from lowest");keys=0;cycles(5);
 page=1;cycles(5);command(4);command(16);ck(rec && !play,"start recording");
 step();page=0;cycles(5);keys=3;timbre=2;env=1;repeat(10)step();
 keys=0;repeat(5)step();page=1;cycles(5);command(16);ck(!rec && valid,"stop recording saves clip");
 command(32);ck(play && !rec,"play saved clip");
 page=0;cycles(5);keys=64;step();step();ck(notes==3 && oct==2 && shape==2 && envelope,"playback restores notes and settings, suppresses live keys");
 repeat(20)step();ck(!play,"playback ends once");
 keys=0;page=1;cycles(5);command(32);ck(play,"replay available");command(32);ck(!play && notes==0,"manual stop releases playback");
 command(64);ck(!valid,"clear clip");command(32);ck(!play,"empty clip cannot play");
 command(16);command(32);ck(!rec && !play,"play command first stops recording");
 command(16);page=0;cycles(5);keys=1;repeat(40)step();
 ck(!rec && limit,"automatic recording limit");cycles(8);
 ck(notes==0,"automatic recording end releases held live notes");
 repeat(5)step();ck(notes==0,"held key cannot reopen after automatic end");
 keys=0;cycles(5);keys=1;cycles(5);ck(notes==1,"release and repress rearms live performance");
 rst=1;cycles(3);ck(!rec && !play && !valid && notes==0,"reset clears modes and clip");
 $display("PASS tb_performance");$finish;
 end
 initial begin #100000000;$fatal(1,"timeout");end
endmodule
