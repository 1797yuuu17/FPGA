// Conservative CH340G transport profile; shared V2 synth and UI.
module top_usb_fallback
 (input clk_50m,input [7:0] key_n,input [3:0] sw,
 output [7:0] led,output [7:0] seg_n,output [3:0] dig_n,
 output [9:0] dac_data,output dac_clk,uart_txd,
 output adc1_oe,adc2_oe,adc1_clk,adc2_clk,beep);
 top_usb #(.PROFILE(1)) engine(.clk_50m(clk_50m),.key_n(key_n),.sw(sw),
 .led(led),.seg_n(seg_n),.dig_n(dig_n),.dac_data(dac_data),.dac_clk(dac_clk),.uart_txd(uart_txd),
 .adc1_oe(adc1_oe),.adc2_oe(adc2_oe),.adc1_clk(adc1_clk),.adc2_clk(adc2_clk),.beep(beep));
endmodule
