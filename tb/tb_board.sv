`timescale 1ns/1ps
module tb_board;
 reg clk=0;always #10 clk=~clk;
 reg [7:0] key_n=255;reg [3:0] sw=0;
 wire [7:0] led,seg;wire [3:0] dig;wire [9:0] data;
 wire dc,a,b,c,d,beep;
 integer buzzer_edges=0;
 always @(posedge beep)buzzer_edges=buzzer_edges+1;
 top #(.DEBOUNCE_CYCLES(8),.BUZZER_TEST(1)) dut(clk,key_n,sw,led,seg,dig,data,dc,a,b,c,d,beep);
 task check;input cond;input [511:0] msg;begin if(!cond)begin $display("FAIL %s",msg);$fatal(1);end end endtask
 task cycles;input integer n;begin repeat(n)@(negedge clk);end endtask
 time changed,rising=0;integer edges=0;reg armed=0;
 always @(data) if(armed)begin
 changed=$time;
 if(!dut.rst)begin check(dc===0,"data changes on DAC falling phase only");check($time-rising>=30,"DAC hold >=30 ns");end
 end
 always @(posedge dc)if(armed)begin
 rising=$time;
 edges=edges+1;check($time-changed>=30,"DAC setup >=30 ns");check(^data!==1'bx,"known DAC sample");
 end
 initial begin
 cycles(300);armed=1;check(data==512,"boot midpoint");check({a,b,c,d,beep}==5'b11000,"ADC disabled and buzzer silent");
 key_n[0]=0;cycles(3);key_n[0]=1;cycles(30);check(led[0]==0,"short bounce ignored");
 key_n[0]=0;cycles(30);check(led[0]==1,"stable press accepted");cycles(400000);
 check(dut.count==1,"board key reaches core");
 check(buzzer_edges>5,"board key drives enabled diagnostic buzzer");
 key_n[7]=0;cycles(10);check(data==512,"reset midpoint");check(dut.count==0,"board reset");
 check(beep===0,"board reset mutes diagnostic buzzer");
 key_n=255;cycles(300);check(edges>100,"continuous DAC clock");
 sw[3]=1;cycles(300);key_n[0]=0;cycles(2000);
 check(dut.count==0,"control page keys must not become notes");
 $display("PASS tb_board");$finish;
 end
endmodule
