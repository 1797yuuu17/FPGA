// Millisecond-enabled ascending arpeggiator; no derived clock.
module arp_engine(input clk,input rst,input ms_tick,input enabled,
 input [1:0] speed,input [6:0] keys,output [6:0] notes);
 reg [6:0] old_keys;reg old_enable;reg [1:0] old_speed;
 reg [8:0] age;reg [2:0] selected;
 reg [2:0] first_note,next_note;integer i;
 wire [8:0] period_ms=speed==0?9'd500:speed==1?9'd250:9'd125;
 always @* begin
 first_note=0;
 for(i=6;i>=0;i=i-1)if(keys[i])first_note=i;
 next_note=first_note;
 for(i=6;i>=0;i=i-1)if(keys[i] && i>selected)next_note=i;
 end
 always @(posedge clk)begin
 if(rst)begin old_keys<=0;old_enable<=0;old_speed<=1;age<=0;selected<=0;end
 else begin
 old_keys<=keys;old_enable<=enabled;old_speed<=speed;
 if(!enabled || keys==0 || keys!=old_keys || enabled!=old_enable || speed!=old_speed)begin age<=0;selected<=first_note;end
 else if(ms_tick)begin
 if(age==period_ms-1)begin age<=0;selected<=next_note;end else age<=age+1'b1;
 end end end
 assign notes=rst?7'b0:!enabled?keys:
   (keys[selected] && age<(period_ms>>1))?(7'b1<<selected):7'b0;
endmodule
