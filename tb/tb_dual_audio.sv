`timescale 1ns/1ps
module tb_dual_audio;
 reg clk=0;always #10 clk=~clk;
 reg [7:0] keys=255;reg [3:0] sw=0;
 wire [7:0] l,s,ul,us,dl,ds;wire [3:0] d,ud,dd;
 wire [9:0] data,old_data;wire tx,old_tx,dc,old_dc,oe1,oe2,beep;
 top_dual #(.DEBOUNCE_CYCLES(2)) dut(.clk_50m(clk),.key_n(keys),.sw(sw),
 .led(l),.seg_n(s),.dig_n(d),.dac_data(data),.dac_clk(dc),.uart_txd(tx),.adc1_oe(oe1),.adc2_oe(oe2),.beep(beep));
 top_usb #(.DEBOUNCE_CYCLES(2),.PROFILE(1)) usb(.clk_50m(clk),.key_n(keys),.sw(sw),
 .led(ul),.seg_n(us),.dig_n(ud),.uart_txd(old_tx));
 top_dac #(.DEBOUNCE_CYCLES(2)) dac(.clk_50m(clk),.key_n(keys),.sw(sw),
 .led(dl),.seg_n(ds),.dig_n(dd),.dac_data(old_data),.dac_clk(old_dc));
 integer serial_file,pcm_file,j,nonzero=0;reg [7:0] b;reg capture=1;
 time changed=0,rising=0,last_rise=0;
 always @(data)if(!dut.rst)begin
 changed=$time;
 if(dc!==0 || $time-rising<30)$fatal(1,"DAC falling phase/hold window");
 end
 always @(posedge dc)if(!dut.rst)begin
 rising=$time;
 if($time-changed<30)$fatal(1,"DAC setup window");
 if(last_rise!=0 && $time-last_rise!=80)$fatal(1,"DAC clock discontinuity");
 last_rise=$time;
 end
 always @(posedge dut.rst) last_rise=0;
 always @(negedge clk)begin
 if(!dut.rst)begin
 if(data!==old_data || dc!==old_dc)$fatal(1,"DAC differs from latest standalone gain/timing");
 if(tx!==old_tx)$fatal(1,"USB serial differs from standalone profile1");
 if(dut.pcm!==usb.pcm || dut.pcm!==dac.pcm)$fatal(1,"shared synth changed");
 if({l,s,d}!=={ul,us,ud} || {l,s,d}!=={dl,ds,dd})$fatal(1,"controls/display changed");
 if({oe1,oe2,beep}!==3'b110)$fatal(1,"unsafe unused outputs");
 if(dut.audio_valid && capture)begin
 $fdisplay(pcm_file,"%0d",dut.audio_pcm);
 if(dut.audio_pcm!=0)nonzero=nonzero+1;
 end
 end
 end
 task command;input [7:0] mask;begin keys=mask;#100000;keys=255;#100000;end endtask
 initial begin
 serial_file=$fopen("serial_dual.hex","w");pcm_file=$fopen("pcm_dual.txt","w");
 #100000;keys=8'hf0;#6000000;keys=255;sw=1;#1000000;keys=8'hfa;
 #6000000;keys=255;sw=2;#1000000;keys=8'hfd;#6000000;keys=255;
 sw=8;#100000;command(8'hfe);command(8'hfb);command(8'hf7);
 sw=0;#100000;keys=8'hf8;#12000000;keys=255;#10000000;
 if(dut.dropped_frames!=0 || nonzero<100)$fatal(1,"USB data loss or silent audio");
 capture=0;#6000000;$fclose(serial_file);$fclose(pcm_file);
 keys=8'hfe;#1000000;keys[7]=0;#1000;
 if(data!==512 || tx!==1 || dut.count!==0)$fatal(1,"reset did not mute both outputs");
 keys=255;#100000;
 if(dut.audio_pcm!==0 || data!==512)$fatal(1,"stale audio after reset");
 $display("PASS tb_dual_audio");$finish;
 end
 initial forever begin
 @(negedge tx);#3255;
 for(j=0;j<8;j=j+1)begin b[j]=tx;#2170;end
 if(tx!==1)$fatal(1,"UART stop bit");
 if(capture)$fdisplay(serial_file,"%02x",b);
 end
 initial begin #60000000;$fatal(1,"timeout");end
endmodule
