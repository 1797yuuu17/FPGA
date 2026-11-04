// Pocket Lab-F1 passive buzzer diagnostic, 50MHz reference.
// Single-note square wave, three octaves above DAC notes (C7..B7),
// within the board manual's suggested 2..5kHz drive range.
// When multiple keys are held, lowest key number has priority.
// K3/K4 use 12.5% duty to compensate the reported loudness peak;
// other keys keep 50%. This changes buzzer harmonics, not the note frequency.
module buzzer_test(input clk,input rst,input [6:0] keys,output beep);
 reg [31:0] phase;
 reg [31:0] step;
 reg attenuate;
 always @* begin
 attenuate=0;
 if(keys[0])step=179788;
 else if(keys[1])step=201805;
 else if(keys[2])begin step=226518;attenuate=1;end
 else if(keys[3])begin step=239988;attenuate=1;end
 else if(keys[4])step=269377;
 else if(keys[5])step=302366;
 else if(keys[6])step=339394;
 else step=0;
 end
 always @(posedge clk)begin
 if(rst || keys==0)phase<=0;else phase<=phase+step;
 end
 assign beep=!rst && (|keys) && phase[31] && (!attenuate || phase[30:29]==0);
endmodule
