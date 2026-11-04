`timescale 1ns/1ps
module tb_uart_tx;
 reg clk=0;always #10 clk=~clk;
 reg rst=1,valid=0;reg[7:0] data=0; wire ready,tx;
 uart_tx u(clk,rst,data,valid,ready,tx);
 integer k,j;reg[7:0] expected,got;
 initial begin
 repeat(5)@(negedge clk);rst=0;
 for(k=0;k<4;k=k+1) begin
 case(k)0:expected=0;1:expected=255;2:expected=85;3:expected=170;endcase
 @(negedge clk);data=expected;valid=1;
 @(negedge clk);valid=0;
 #540; if(tx!==0)$fatal(1,"start bit");
 for(j=0;j<8;j=j+1)begin #1085;got[j]=tx;end
 if(got!==expected)$fatal(1,"wrong byte %h %h",got,expected);
 #1085;if(tx!==1)$fatal(1,"stop bit");
 wait(ready);end
 $display("PASS tb_uart_tx");$finish;end
 initial begin #1000000;$fatal(1,"timeout");end
endmodule
