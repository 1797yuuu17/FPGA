`timescale 1ns/1ps
module tb_pcm_packetizer;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,v=0,ready=1;reg signed[15:0] pcm;
 wire valid;wire[7:0] data;wire[31:0] drops;
 pcm_packetizer u(clk,rst,v,pcm,valid,data,ready,drops);
 integer f,n,count=0;
 always @(posedge clk)if(!rst && valid && ready)begin $fdisplay(f,"%02x",data);count=count+1;end
 initial begin f=$fopen("packets.hex","w");repeat(5)@(negedge clk);rst=0;
 for(n=0;n<384;n=n+1)begin @(negedge clk);v=1;pcm=n-192;@(negedge clk);v=0;repeat(8)@(negedge clk);end
 wait(count==816);if(drops!=0)$fatal(1,"unexpected drops");
 // Force queue overflow and verify entire input frames are discarded.
 ready=0;for(n=0;n<1024;n=n+1)begin @(negedge clk);v=1;pcm=n;@(negedge clk);v=0;end
 if(drops<4)$fatal(1,"overflow missing");
 $fclose(f);$display("PASS tb_pcm_packetizer");$finish;end
 initial begin #2000000;$fatal(1,"timeout");end
endmodule
