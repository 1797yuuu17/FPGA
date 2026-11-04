module pcm_packetizer #(parameter PROFILE=0)
 (input clk,rst,sample_valid,input signed [15:0] pcm,
 output tx_valid,output reg [7:0] tx_data,input tx_ready,output reg [31:0] drop_count);
 reg [15:0] mem[0:511];reg [15:0] seqs[0:3];reg [31:0] indices[0:3];
 reg [2:0] written,read_count;reg [6:0] sample_pos;reg accept;
 reg [15:0] seq;reg [31:0] sample_index;
 wire [2:0] occupancy=written-read_count;
 wire room=occupancy<4;
 wire take=(sample_pos==0)?room:accept;
 always @(posedge clk)begin
 if(rst)begin written<=0;sample_pos<=0;accept<=0;seq<=0;sample_index<=0;drop_count<=0;end
 else if(sample_valid)begin
 if(sample_pos==0)begin accept<=room;if(room)begin seqs[written[1:0]]<=seq;indices[written[1:0]]<=sample_index;end end
 if(take)mem[{written[1:0],sample_pos}]<=pcm;
 sample_index<=sample_index+1'b1;sample_pos<=sample_pos+1'b1;
 if(sample_pos==127)begin seq<=seq+1'b1;if(take)written<=written+1'b1;else drop_count<=drop_count+1'b1;end
 end end
 function [15:0] crc_byte;input [15:0] c;input [7:0] b;reg [15:0] v;integer n;
 begin v=c^{b,8'b0};for(n=0;n<8;n=n+1)v=v[15]?(v<<1)^16'h1021:v<<1;crc_byte=v;end endfunction
 reg active,prepared;reg [8:0] pos;reg [15:0] crc,mem_q;
 wire [8:0] payload_pos=pos-14;
 always @(posedge clk)mem_q<=mem[{read_count[1:0],payload_pos[7:1]}];
 assign tx_valid=active && prepared;
 always @*begin
 case(pos)
 0:tx_data=8'h50;1:tx_data=8'h4c;2:tx_data=8'h46;3:tx_data=8'h31;
 4:tx_data=1;5:tx_data=PROFILE;
 6:tx_data=seqs[read_count[1:0]][7:0];7:tx_data=seqs[read_count[1:0]][15:8];
 8:tx_data=indices[read_count[1:0]][7:0];9:tx_data=indices[read_count[1:0]][15:8];
 10:tx_data=indices[read_count[1:0]][23:16];11:tx_data=indices[read_count[1:0]][31:24];
 12:tx_data=128;13:tx_data=0;270:tx_data=crc[7:0];271:tx_data=crc[15:8];
 default:tx_data=pos[0]?mem_q[15:8]:mem_q[7:0];
 endcase end
 always @(posedge clk)begin
 if(rst)begin read_count<=0;active<=0;prepared<=0;pos<=0;crc<=16'hffff;end
 else if(!active)begin if(written!=read_count)begin active<=1;prepared<=0;pos<=0;crc<=16'hffff;end end
 else if(!prepared)prepared<=1;
 else if(tx_ready)begin
 prepared<=0;
 if(pos>=4 && pos<270)crc<=crc_byte(crc,tx_data);
 if(pos==271)begin active<=0;read_count<=read_count+1'b1;end else pos<=pos+1'b1;
 end end
endmodule
