`timescale 1ns/1ps
// Default release configuration: audio goes to DAC, never the diagnostic buzzer.
// Accelerate sample pacing only; real 50MHz clock and DAC edge timing remain.
module tb_dac;
 reg clk=0; always #10 clk=~clk;
 reg [7:0] keys=255; reg [3:0] sw=0;
 wire [7:0] led,seg; wire [3:0] dig; wire [9:0] data;
 wire dc,a,b,c,d,beep;
 top #(.DEBOUNCE_CYCLES(8),.SAMPLE_DIV(16)) dut(clk,keys,sw,led,seg,dig,data,dc,a,b,c,d,beep);
 task check; input cond; input [511:0] msg;
 begin if(!cond)begin $display("FAIL %s",msg);$fatal(1);end end endtask
 task samples; input integer n;
 begin repeat(n*16)@(negedge clk);end endtask
 integer shape,i,low,high,transitions,last_value; reg monitoring=0;
 always @(posedge clk) if(monitoring) begin
   check(beep===0,"audio release must keep diagnostic buzzer muted");
 end
 initial begin
 repeat(300)@(negedge clk);monitoring=1;
 check(data==512,"default boot midpoint");
 for(shape=0;shape<3;shape=shape+1)begin
   sw=shape; samples(4); keys=8'hf0; samples(12000);
   check(dut.count==4,"four keys allocated in audio release");
   low=1023;high=0;transitions=0;last_value=data;
   for(i=0;i<2000;i=i+1)begin
     samples(1);
     check(^data!==1'bx,"known audio samples");
     check(data>=448 && data<=575,"low initial DAC level stays within one eighth full scale");
     if(data<low)low=data;if(data>high)high=data;
     if(data!=last_value)transitions=transitions+1;last_value=data;
   end
   $display("DAC shape=%0d min=%0d max=%0d transitions=%0d",shape,low,high,transitions);
   // Four square voices have about 49 edges in this 20ms sample window.
   // Sine/triangle change more often; all must produce a changing bipolar signal.
   check(low<512 && high>512 && transitions>10,"bipolar changing chord reaches DAC");
   keys[0]=1;samples(10);
   check(dut.count==4,"released note retains envelope tail");
   samples(3000);check(dut.count==3,"one tail ends while remaining chord plays");
   keys=255;samples(10000);
   check(dut.count==0 && data==512,"all releases return DAC to midpoint");
 end
 keys=8'hfe;samples(600);keys[7]=0;repeat(10)@(negedge clk);
 check(data==512 && dut.count==0,"reset mutes DAC while playing");
 $display("PASS tb_dac");$finish;
 end
 initial begin #100000000;$fatal(1,"timeout");end
endmodule
