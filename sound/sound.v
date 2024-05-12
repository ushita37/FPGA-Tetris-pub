module sound(input CLK, input RESET, input [4:0] BTN, output SPEAKER0, output SPEAKER1);
   reg [15:0] count;
   reg 	      s;
   always @(posedge CLK) begin
      if(RESET==1) begin
	 count <= 0;
	 s     <= 0;
      end else if(count==56789) begin
	 count <= 0;
	 s     <= ~s;
      end else begin
	 count <= count + 1;
      end
   end
   assign SPEAKER0 = s;
   assign SPEAKER1 = ~SPEAKER0;
endmodule // sound


module clock_25MHz(output reg clk_25MHz);
   initial clk_25MHz = 0;
   always  #20 clk_25MHz = ~clk_25MHz; // 1/(25x10^6)=40nsec 
endmodule

module soundSim;
   wire CLK25M,speaker0,speaker1;
   reg [4:0] btn;
   reg       reset;
   clock_25MHz clock_25MHz(CLK25M);
   sound sound(CLK25M,reset,btn,speaker0,speaker1);
   initial begin
      $display("reset  speaker0 time(ns)");
      $monitor(" %b        %b   ",reset,speaker0,$stime);
      btn = 4'b0000;
      @(posedge CLK25M) reset = 1;
      @(posedge CLK25M) reset = 0;
      #20000000;
      $finish;
   end
endmodule // soundSim

