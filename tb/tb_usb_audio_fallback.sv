`timescale 1ns/1ps
module tb_usb_audio_fallback;
 reg clk=0;always #10 clk=~clk;
 reg[7:0] keys=255;reg[3:0] sw=0;
 wire[7:0] l1,l2,s1,s2;wire[3:0] d1,d2;wire[9:0] dac;
 wire tx,oe1,oe2,beep;integer serial_file,pcm_file,j;reg[7:0] b;
 top_usb #(.DEBOUNCE_CYCLES(2),.PROFILE(1)) u(.clk_50m(clk),.key_n(keys),.sw(sw),.led(l1),.seg_n(s1),.dig_n(d1),.dac_data(dac),.uart_txd(tx),.adc1_oe(oe1),.adc2_oe(oe2),.beep(beep));
 top #(.DEBOUNCE_CYCLES(2)) baseline(.clk_50m(clk),.key_n(keys),.sw(sw),.led(l2),.seg_n(s2),.dig_n(d2));
 always @(negedge clk)if(!u.rst)begin
 if(u.pcm!==baseline.pcm || l1!==l2 || s1!==s2 || d1!==d2)$fatal(1,"V2 behavior changed");
 if(oe1!==1 || oe2!==1 || beep!==0 || dac!==512)$fatal(1,"unsafe board outputs");
 if(u.audio_valid)$fdisplay(pcm_file,"%0d",u.audio_pcm);
 end
 initial begin serial_file=$fopen("serial_fallback.hex","w");pcm_file=$fopen("usb_pcm_fallback.txt","w");
 #100000; keys=8'hf0;#4000000;keys=255;sw=1;#1000000;keys=8'hfa;
 #4000000;keys=255;sw=2;#1000000;keys=8'hfd;#4000000;keys=255;
 sw=8;#1000000;keys=8'hfb;#2000000;keys=255;#1000000;sw=0;
 #1000000;keys=8'hf8;#8000000;keys=255;#10000000;
 if(u.dropped_frames!=0)$fatal(1,"unexpected packet loss");
 $fclose(serial_file);$fclose(pcm_file);$display("PASS tb_usb_audio_fallback");$finish;end
 initial forever begin
 @(negedge tx);#3255;
 for(j=0;j<8;j=j+1)begin b[j]=tx;#2170;end
 if(tx!==1)$fatal(1,"UART stop bit");$fdisplay(serial_file,"%02x",b);
 end
endmodule
