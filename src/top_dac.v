module top_dac #(parameter DEBOUNCE_CYCLES=250000, parameter SAMPLE_DIV=500,
 parameter TEST_TONE=0, parameter OUTPUT_SHIFT=1, parameter BUZZER_TEST=0, parameter MS_DIV=50000)
 (input clk_50m,input [7:0] key_n,input [3:0] sw,
 output [7:0] led,output reg [7:0] seg_n,output reg [3:0] dig_n,
 output reg [9:0] dac_data,output dac_clk,
 output adc1_oe,adc2_oe,adc1_clk,adc2_clk,beep);
 reg [7:0] boot=0; reg [1:0] reset_pipe=0;
 wire rst=!(&boot)||!reset_pipe[1];
 always @(posedge clk_50m) begin
 if(!(&boot))boot<=boot+1'b1;
 reset_pipe<={reset_pipe[0],key_n[7]};
 end
 reg [6:0] sync1,sync2,stable;reg [3:0] sw1,sw2;
 reg [17:0] debounce[0:6]; integer i;
 always @(posedge clk_50m)begin
 if(rst)begin sync1<=0;sync2<=0;stable<=0;sw1<=0;sw2<=0;for(i=0;i<7;i=i+1)debounce[i]<=0;end
 else begin
 sync1<=~key_n[6:0];sync2<=sync1;sw1<=sw;sw2<=sw1;
 for(i=0;i<7;i=i+1)if(sync2[i]==stable[i])debounce[i]<=0;
 else if(debounce[i]==DEBOUNCE_CYCLES-1)begin stable[i]<=sync2[i];debounce[i]<=0;end
 else debounce[i]<=debounce[i]+1'b1;
 end end
 reg [8:0] divider; wire tick=divider==SAMPLE_DIV-1;
 always @(posedge clk_50m)if(rst||tick)divider<=0;else divider<=divider+1'b1;
 wire signed [15:0] pcm;wire [2:0] count;
 reg [15:0] ms_divider;wire ms_tick=ms_divider==MS_DIV-1;
 always @(posedge clk_50m)if(rst||ms_tick)ms_divider<=0;else ms_divider<=ms_divider+1'b1;
 reg control_page;reg [17:0] page_debounce;
 always @(posedge clk_50m)begin
 if(rst)begin control_page<=0;page_debounce<=0;end
 else if(sw2[3]==control_page)page_debounce<=0;
 else if(page_debounce==DEBOUNCE_CYCLES-1)begin control_page<=sw2[3];page_debounce<=0;end
 else page_debounce<=page_debounce+1'b1;
 end
 wire [6:0] performance_keys;wire [1:0] octave_out,timbre_out,octave_selected,speed;
 wire env_out,arp_enabled,recording,playing,has_clip,limited;
 performance_ctrl_usb performance(clk_50m,rst,ms_tick,stable,control_page,sw2[1:0],sw2[2],
 performance_keys,octave_out,timbre_out,env_out,octave_selected,arp_enabled,speed,recording,playing,has_clip,limited);
 synth_core core(clk_50m,rst,tick,TEST_TONE?7'b0100000:performance_keys,timbre_out,env_out,pcm,count,octave_out);
 reg [1:0] dc;
 // Continuous 12.5MHz DAC clock. Data changes on falling edge, 40ns before next rising edge.
 assign dac_clk=dc[1];
 wire signed [15:0] quiet_pcm=pcm >>> OUTPUT_SHIFT;
 wire [9:0] offset_sample=quiet_pcm[15:6]^10'b1000000000;
 always @(posedge clk_50m)begin
 if(rst)begin dc<=0;dac_data<=512;end
 else begin dc<=dc+1'b1;if(dc==3)dac_data<=offset_sample;end end
 wire buzzer_wave;
 buzzer_test buzzer(clk_50m,rst,performance_keys,buzzer_wave);
 assign beep=BUZZER_TEST?buzzer_wave:1'b0;
 assign adc1_oe=1'b1,adc2_oe=1'b1,adc1_clk=1'b0,adc2_clk=1'b0;
 assign led={count!=0,stable};
 reg [15:0] scan; reg [1:0] digit;reg [3:0] value;
 always @(posedge clk_50m)if(rst)begin scan<=0;digit<=0;end
 else if(scan==49999)begin scan<=0;digit<=digit+1'b1;end else scan<=scan+1'b1;
 always @* begin
 if(control_page)case(digit)
 0:value=recording?1:playing?2:limited?3:0;
 1:value={2'b0,octave_selected};2:value={3'b0,arp_enabled};default:value={2'b0,speed};endcase
 else case(digit)0:value={1'b0,count};1:value={2'b0,octave_out};2:value={3'b0,env_out};default:value={2'b0,timbre_out};endcase
 case(value)
 0:seg_n=8'hc0;1:seg_n=8'hf9;2:seg_n=8'ha4;3:seg_n=8'hb0;4:seg_n=8'h99;
 default:seg_n=8'hff;endcase
 if((digit==0 && recording)||(digit==1 && playing)||(digit==3 && has_clip))seg_n[7]=0;
 dig_n=4'b1111;if(!rst && scan>1)dig_n=~(4'b0001<<digit);
 end
endmodule

