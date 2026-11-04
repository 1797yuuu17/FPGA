// Four independent DDS voices; sample rate 100 kHz. Board wrapper supplies tick.
module synth_core(input clk,input rst,input tick,input [6:0] keys,
 input [1:0] timbre,input long_env,output signed [15:0] pcm,output reg [2:0] active_count,input [1:0] octave);
 reg [6:0] previous;
 reg [3:0] gate;
 reg [2:0] note[0:3];
 reg [31:0] phase[0:3];
 reg [1:0] voice_octave[0:3];reg [31:0] phase_step[0:3];integer step_i;
 reg [15:0] env[0:3];
 reg [2:0] state[0:3];
 reg [1:0] wave[0:3];
 reg [3:0] mode;
 reg [1:0] victim;
 wire signed [15:0] sample[0:3];
 integer i,k,j,chosen,v,new_note;
 integer candidate,jc;
 reg [1:0] choice;
 reg [6:0] choice_keys;
 reg [3:0] free_mask,release_mask;
 reg [6:0] mask_keys;
 integer mask_i;
 always @(posedge clk)begin
 if(rst)begin free_mask<=0;release_mask<=0;mask_keys<=0;end
 else begin mask_keys<=keys;for(mask_i=0;mask_i<4;mask_i=mask_i+1)begin
 free_mask[mask_i]<=!gate[mask_i] && env[mask_i]==0;
 release_mask[mask_i]<=!gate[mask_i] || !keys[note[mask_i]];
 end end end
 // Separate allocation search from voice writeback to keep the 50MHz path short.
 always @* begin
 candidate=-1;
 for(jc=3;jc>=0;jc=jc-1)if(free_mask[jc])candidate=jc;
 if(candidate<0)for(jc=3;jc>=0;jc=jc-1)if(release_mask[jc])candidate=jc;
 if(candidate<0)candidate=victim;
 end
 always @(posedge clk)begin
 if(rst)begin choice<=0;choice_keys<=0;end
 else begin choice<=candidate[1:0];choice_keys<=mask_keys;end
 end
 function [31:0] increment; input [2:0] n; begin
 case(n)
 0:increment=11236733; 1:increment=12612589; 2:increment=14156895;
 3:increment=14998623; 4:increment=16836272; 5:increment=18897856;
 default:increment=21212230;
 endcase end endfunction
 // Resolve note/octave away from the tick writeback path. New phase starts at zero;
 // phase_step settles on the following master clock, before the next sample tick.
 always @(posedge clk)for(step_i=0;step_i<4;step_i=step_i+1)begin
 if(rst)phase_step[step_i]<=11236733;
 else case(voice_octave[step_i])
 0:phase_step[step_i]<=increment(note[step_i])>>1;
 2:phase_step[step_i]<=increment(note[step_i])<<1;
 default:phase_step[step_i]<=increment(note[step_i]);
 endcase end
 genvar g; generate for(g=0;g<4;g=g+1) begin: voices
 waveform w(phase[g],wave[g],sample[g]);
 end endgenerate
 mixer_pipe mix(clk,rst,sample[0],env[0],sample[1],env[1],sample[2],env[2],sample[3],env[3],pcm);
 always @* begin
 active_count=0;
 for(v=0;v<4;v=v+1) if(gate[v] || env[v]!=0) active_count=active_count+1'b1;
 end
 always @(posedge clk) begin
 if(rst) begin
 previous<=0;gate<=0;victim<=0;
 for(i=0;i<4;i=i+1) begin note[i]<=0;phase[i]<=0;env[i]<=0;state[i]<=0;wave[i]<=0;mode[i]<=0;voice_octave[i]<=1;end
 end else if(tick) begin
 previous<=previous & keys;
 for(i=0;i<4;i=i+1) begin
 phase[i]<=phase[i]+phase_step[i];
 if(gate[i] && !keys[note[i]]) begin gate[i]<=0;state[i]<=4;end
 else case(state[i])
 0:env[i]<=0;
 1:if(env[i]>=65535-(mode[i]?22:132))begin env[i]<=65535;state[i]<=2;end
   else env[i]<=env[i]+(mode[i]?16'd22:16'd132);
 2:if(env[i]<=(mode[i]?45875:16384)+(mode[i]?2:5))begin env[i]<=mode[i]?45875:16384;state[i]<=3;end
   else env[i]<=env[i]-(mode[i]?16'd2:16'd5);
 3:env[i]<=mode[i]?45875:16384;
 4:if(env[i]<=(mode[i]?3:7))begin env[i]<=0;state[i]<=0;end
   else env[i]<=env[i]-(mode[i]?16'd3:16'd7);
 default:begin state[i]<=0;env[i]<=0;end
 endcase
 end
 // Allocate one pending key per sample. Seven keys require at most 70us.
 new_note=-1;
 for(k=6;k>=0;k=k-1)if(keys[k] && !previous[k])new_note=k;
 if(new_note>=0 && choice_keys==keys) begin
 previous[new_note]<=1;
 chosen=choice;
 if(chosen>=0) begin
 gate[chosen]<=1;note[chosen]<=new_note[2:0];victim<=choice+1'b1;
 phase[chosen]<=0;env[chosen]<=0;state[chosen]<=1;
 wave[chosen]<=timbre==3?0:timbre;mode[chosen]<=long_env;
 voice_octave[chosen]<=octave;
 end
 end
 end
 end
endmodule
