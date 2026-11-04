// Timestamped performance events, not PCM recording. One volatile clip.
module event_recorder #(parameter MAX_EVENTS=256,parameter MAX_MS=30000)
 (input clk,input rst,input ms_tick,input record_cmd,input play_cmd,input clear_cmd,
 input [11:0] source,output reg [11:0] replay,
 output reg recording,playing,valid,limited);
 reg [31:0] memory[0:MAX_EVENTS-1];
 reg [8:0] length,read_index;
 reg [14:0] record_time,play_time,end_time;
 reg [11:0] last_source;reg first_event;
 wire [7:0] read_address=read_index<MAX_EVENTS?read_index[7:0]:8'b0;
 reg [31:0] read_data;
 // Synchronous read and write permit block RAM inference; RAM is not reset.
 always @(posedge clk)begin
 read_data<=memory[read_address];
 if(!rst && !clear_cmd && !record_cmd && !play_cmd && recording && ms_tick &&
    length<MAX_EVENTS && (first_event || source!=last_source))
   memory[length[7:0]]<={5'b0,record_time,source};
 end
 always @(posedge clk)begin
 if(rst || clear_cmd)begin
 length<=0;read_index<=0;record_time<=0;play_time<=0;end_time<=0;
 replay<=0;recording<=0;playing<=0;valid<=0;limited<=0;last_source<=0;first_event<=1;
 end else if(record_cmd)begin
 playing<=0;replay<=0;
 if(recording)begin recording<=0;end_time<=record_time+1'b1;valid<=length!=0;end
 else begin recording<=1;valid<=0;limited<=0;length<=0;record_time<=0;first_event<=1;end
 end else if(play_cmd)begin
 if(recording)begin recording<=0;end_time<=record_time+1'b1;valid<=length!=0;end
 else if(playing)begin playing<=0;replay<=0;end
 else if(valid)begin playing<=1;play_time<=0;read_index<=0;replay<=0;end
 end else if(ms_tick)begin
 if(recording)begin
 record_time<=record_time+1'b1;
 if(first_event || source!=last_source)begin
 length<=length+1'b1;last_source<=source;first_event<=0;
 if(length==MAX_EVENTS-1)begin recording<=0;valid<=1;limited<=1;end_time<=record_time+1'b1;end
 end
 if(record_time==MAX_MS-1)begin recording<=0;valid<=1;limited<=1;end_time<=record_time+1'b1;end
 end
 if(playing)begin
 if(play_time>=end_time)begin playing<=0;replay<=0;end
 else begin
 play_time<=play_time+1'b1;
 if(read_index<length && read_data[26:12]<=play_time)begin
 replay<=read_data[11:0];read_index<=read_index+1'b1;
 end
 end end
 end
 end
endmodule
