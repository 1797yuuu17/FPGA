`timescale 1ns/1ps
module tb_synth;
 reg clk=0; always #10 clk=~clk;
 reg rst=1, tick=0; reg [6:0] keys=0; reg [1:0] timbre=0; reg long_env=0;
 wire signed [15:0] pcm; wire [2:0] count;
 reg [1:0] octave=1;reg [31:0] phase_before;
 synth_core dut(clk,rst,tick,keys,timbre,long_env,pcm,count,octave);
 task step; begin @(negedge clk);tick=1;@(negedge clk);tick=0;repeat(3) @(negedge clk);end endtask
 task check; input condition; input [511:0] msg; begin if(!condition) begin $display("FAIL %s",msg);$fatal(1);end end endtask
 integer i;
 initial begin
 repeat(4) @(negedge clk);rst=0;step();check(pcm===0,"reset silence");
 keys=7'b0001111;repeat(600)step();check(count==4,"four simultaneous keys");check(dut.env[0]>0,"attack running");
 keys=7'b0010111;step();step();check(dut.gate[0] && dut.note[0]==0,"same-tick release must preserve held oldest note");
 keys=0;repeat(31000)step();
 keys=7'b0001111;repeat(600)step();
 keys=7'b0011111;step();step();check(count==4,"fifth key capacity");
 keys=7'b0011110;step();step();check(dut.gate[0]===1,"stolen old note off must not kill replacement");
 keys=0;repeat(31000)step();check(count==0,"all releases complete");check(pcm===0,"release silence");
 keys=7'b0000001;repeat(10)step();keys=0;step();keys=1;repeat(10)step();check(count>0,"quick retrigger");
 rst=1;step();check(pcm===0,"reset under note");check(count==0,"reset clears allocator");
 keys=0;rst=0;step();long_env=0;keys=1;repeat(12000)step();
 check(dut.env[0]==16384,"short envelope reaches sustain");keys=0;repeat(3000)step();check(count==0,"short sustain release finishes");
 long_env=1;keys=1;repeat(20000)step();
 check(dut.env[0]==45875,"long envelope reaches sustain");keys=0;repeat(1000)step();
 check(dut.env[0]>0 && dut.env[0]<45875,"long envelope release is gradual");
 repeat(16000)step();check(count==0 && pcm===0,"long envelope release finishes");
 rst=1;step();rst=0;octave=0;keys=1;repeat(4)step();
 phase_before=dut.phase[0];step();check(dut.phase[0]-phase_before==5618366,"low octave phase increment");
 octave=2;repeat(3)step();phase_before=dut.phase[0];step();
 check(dut.phase[0]-phase_before==5618366,"held note keeps latched octave");
 keys=0;repeat(3000)step();keys=1;repeat(4)step();phase_before=dut.phase[0];step();
 check(dut.phase[0]-phase_before==22473466,"high octave phase increment");
 $display("PASS tb_synth");$finish;
 end
 initial begin #100000000; $fatal(1,"timeout");end
endmodule
