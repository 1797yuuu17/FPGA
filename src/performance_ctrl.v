// SW4 selects command page. All keys must be released after page/play transitions.
module performance_ctrl #(parameter REC_MAX_MS=30000,parameter REC_MAX_EVENTS=256)
 (input clk,input rst,input ms_tick,input [6:0] keys,
 input control_page,input [1:0] timbre,input long_env,
 output [6:0] notes,output [1:0] octave_out,timbre_out,output env_out,
 output reg [1:0] octave,output reg arp_enabled,output reg [1:0] speed,
 output recording,playing,has_clip,limited);
 reg [6:0] previous;reg old_page,armed,old_playing,old_recording;
 reg record_cmd,play_cmd,clear_cmd;
 wire [6:0] pressed=keys & ~previous;
 wire [6:0] live_keys=(!rst && !control_page && old_page==control_page && armed && !old_playing && !(old_recording && !recording))?keys:7'b0;
 wire [6:0] arpeggio;
 wire [11:0] source={long_env,timbre,octave,arpeggio};
 reg [11:0] live_event;
 always @(posedge clk)if(rst)live_event<=12'd128;else live_event<=source;
 wire [11:0] replay;
 wire [11:0] output_event=playing?replay:live_event;
 assign notes=output_event[6:0];assign octave_out=output_event[8:7];
 assign timbre_out=output_event[10:9];assign env_out=output_event[11];
 arp_engine arp(clk,rst,ms_tick,arp_enabled,speed,live_keys,arpeggio);
 event_recorder #(.MAX_MS(REC_MAX_MS),.MAX_EVENTS(REC_MAX_EVENTS)) recorder(clk,rst,ms_tick,record_cmd,play_cmd,clear_cmd,live_event,replay,recording,playing,has_clip,limited);
 always @(posedge clk)begin
 if(rst)begin previous<=0;old_page<=0;armed<=0;old_playing<=0;old_recording<=0;
 octave<=1;arp_enabled<=0;speed<=1;record_cmd<=0;play_cmd<=0;clear_cmd<=0;end
 else begin
 previous<=keys;old_page<=control_page;old_playing<=playing;old_recording<=recording;
 record_cmd<=0;play_cmd<=0;clear_cmd<=0;
 if(control_page!=old_page || playing!=old_playing || (old_recording && !recording))armed<=0;
 else if(keys==0)armed<=1;
 if(control_page && old_page && armed && playing==old_playing)begin
 if(pressed[0])begin if(octave!=0)octave<=octave-1'b1;end
 else if(pressed[1])begin if(octave!=2)octave<=octave+1'b1;end
 else if(pressed[2])arp_enabled<=!arp_enabled;
 else if(pressed[3])speed<=speed==2?2'd0:speed+1'b1;
 else if(pressed[4])record_cmd<=1;
 else if(pressed[5])play_cmd<=1;
 else if(pressed[6])clear_cmd<=1;
 end
 end end
endmodule
