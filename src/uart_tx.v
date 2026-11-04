// Synchronous ready/valid, fractional bit timing, 8N1.
module uart_tx #(parameter CLK_HZ=50000000,BAUD=921600)
 (input clk,rst,input [7:0] data,input valid,output ready,output tx);
 reg busy;reg [9:0] shift;reg [3:0] bits;reg [26:0] phase;
 wire [27:0] next_phase={1'b0,phase}+BAUD;
 assign ready=!busy;assign tx=busy?shift[0]:1'b1;
 always @(posedge clk)begin
 if(rst)begin busy<=0;shift<=10'h3ff;bits<=0;phase<=0;end
 else if(!busy)begin
 if(valid)begin busy<=1;shift<={1'b1,data,1'b0};bits<=0;phase<=0;end
 end else if(next_phase>=CLK_HZ)begin
 phase<=next_phase-CLK_HZ;shift<={1'b1,shift[9:1]};
 if(bits==9)busy<=0;else bits<=bits+1'b1;
 end else phase<=next_phase;
 end
endmodule
