// 191-tap Q1.17 FIR, sequential MAC; input cadence >= 500 clocks.
// Delay RAM is cleared sequentially after reset; no stale audio is emitted.
module pcm_decimator #(parameter DECIMATION=4, TAPS=191,
 parameter COEFF_FILE="../src/usb_fir_coeffs.hex")
 (input clk,rst,in_valid,input signed [15:0] in_pcm,
 output reg out_valid,output reg signed [15:0] out_pcm);
 reg signed [17:0] coeff[0:TAPS-1];reg signed [15:0] history[0:255];
 initial $readmemh(COEFF_FILE,coeff);
 reg [7:0] wr,rd,tap,clear_addr;reg clearing,busy,emit;
 reg [3:0] decim;reg signed [43:0] acc;
 wire signed [33:0] product=history[rd]*coeff[tap];
 wire signed [43:0] sum=acc+{{10{product[33]}},product};
 wire signed [43:0] rounded=(sum+44'sd65536)>>>17;
 always @(posedge clk)begin
 out_valid<=0;
 if(rst)begin wr<=0;rd<=0;tap<=0;busy<=0;clearing<=1;clear_addr<=0;decim<=0;acc<=0;emit<=0;out_pcm<=0;end
 else if(clearing)begin history[clear_addr]<=0;if(clear_addr==255)clearing<=0;else clear_addr<=clear_addr+1'b1;end
 else if(in_valid && !busy)begin
 history[wr]<=in_pcm;rd<=wr;wr<=wr+1'b1;tap<=0;acc<=0;busy<=1;
 emit<=decim==DECIMATION-1;
 if(decim==DECIMATION-1)decim<=0;else decim<=decim+1'b1;
 end else if(busy)begin
 if(tap==TAPS-1)begin
 busy<=0;
 if(emit)begin out_valid<=1;
 if(rounded>32767)out_pcm<=32767;
 else if(rounded< -32768)out_pcm<=-32768;else out_pcm<=rounded[15:0];end
 end else begin acc<=sum;tap<=tap+1'b1;rd<=rd-1'b1;end
 end
 end
endmodule
